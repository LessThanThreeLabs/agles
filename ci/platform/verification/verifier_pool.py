import sys

import eventlet

from eventlet import queue

from build_core import CloudBuildCore
from build_verifier import BuildVerifier
from settings.verification_server import VerificationServerSettings
from util.log import Logged
from virtual_machine.docker import DockerVm


@Logged()
class VerifierPool(object):
	def __init__(self, max_verifiers=None, min_unallocated=None, uri_translator=None):
		self.max_verifiers = max_verifiers
		self.min_unallocated = min_unallocated

		max_verifiers = self._get_max_verifiers()
		min_unallocated = self._get_min_unallocated()
		assert max_verifiers >= min_unallocated

		self.uri_translator = uri_translator

		self.free_slots = queue.Queue()
		self.to_remove_free = set()

		self.unallocated_slots = []
		self.allocated_slots = []

		self.to_unallocate = []
		self.to_allocate = []

		self.verifiers = {}

		self._initializing = False
		self._initialize_continuation = None

		self.reinitialize(max_verifiers=max_verifiers, min_unallocated=min_unallocated)

	def reinitialize(self, max_verifiers=None, min_unallocated=None):
		# We use self._initializing as a lock for greenlets
		if not self._initializing:
			self._initializing = True
			self._reinitialize(max_verifiers, min_unallocated)
			self._initializing = False
		else:
			self._initialize_continuation = lambda: self._reinitialize(max_verifiers, min_unallocated)

	def _reinitialize(self, max_verifiers=None, min_unallocated=None):
		old_max = self._get_max_verifiers()
		self.max_verifiers = max_verifiers
		self.min_unallocated = min_unallocated
		self._trim_pool_size(old_max)
		self._increase_pool_size()
		self._fill_to_min_unallocated()
		if self._initialize_continuation:
			continuation = self._initialize_continuation
			self._initialize_continuation = None
			continuation()

	def _get_max_verifiers(self):
		return self.max_verifiers if self.max_verifiers is not None else VerificationServerSettings.max_virtual_machine_count

	def _get_min_unallocated(self):
		return self.min_unallocated if self.min_unallocated is not None else VerificationServerSettings.static_pool_size

	def teardown(self):
		for i in self.unallocated_slots + self.allocated_slots:
			self.remove_verifier(i)

	def get(self):
		while True:
			unallocated = self.get_first_unallocated()

			if unallocated is not None:
				self.allocated_slots.append(unallocated)
				self._fill_to_min_unallocated()
				return self.verifiers[unallocated]
			try:
				free = self.get_first_free(block=False)
			except queue.Empty:
				eventlet.sleep(0.1)
			else:
				break
		try:
			self._spawn_verifier(free)
		except:
			self.free_slots.put(free)
			raise
		return self.verifiers[free]

	def put(self, verifier):
		slot = self._get_slot(verifier)
		self.unallocated_slots.append(slot)
		self.allocated_slots.remove(slot)
		self._trim_pool_size()

	def remove(self, verifier):
		slot = self._get_slot(verifier)

		del self.verifiers[slot]
		# Abandon slots that are higher than the current cap
		if self._get_max_verifiers() > slot:
			self.free_slots.put(slot)

		if slot in self.unallocated_slots:
			self.unallocated_slots.remove(slot)
		elif slot in self.allocated_slots:
			self.allocated_slots.remove(slot)

		self._fill_to_min_unallocated()

	def _get_slot(self, verifier):
		for slot, v in self.verifiers.items():
			if v == verifier:
				return slot
		return None

	def get_first_unallocated(self):
		if self.unallocated_slots:
			unallocated_slot = self.unallocated_slots.pop()
			return unallocated_slot
		return None

	def get_first_free(self, block=True):
		slot = self.free_slots.get(block=block)
		while slot in self.to_remove_free:
			self.to_remove_free.remove(slot)
			slot = self.free_slots.get(block=block)
		return slot

	def _lock_verifier_slot(self, verifier_number, allocated):
		assert verifier_number not in self.verifiers

		limbo_slots = self.to_allocate if allocated else self.to_unallocate
		limbo_slots.append(verifier_number)

	def _unlock_verifier_slot(self, verifier_number, allocated):
		limbo_slots = self.to_allocate if allocated else self.to_unallocate
		limbo_slots.remove(verifier_number)

	def _spawn_verifier_unsafe(self, verifier_number, allocated):
		self.verifiers[verifier_number] = self.spawn_verifier(verifier_number)
		if allocated:
			self.allocated_slots.append(verifier_number)
		else:
			if verifier_number >= self._get_max_verifiers():
				self.remove_verifier(verifier_number)
			else:
				self.unallocated_slots.append(verifier_number)

	def _spawn_verifier(self, verifier_number, allocated=True):
		self._lock_verifier_slot(verifier_number, allocated)
		try:
			self._spawn_verifier_unsafe(verifier_number, allocated)
		finally:
			self._unlock_verifier_slot(verifier_number, allocated)

	def _spawn_verifier_multiple_attempts(self, verifier_number, allocated=True, attempts=10):
		self._lock_verifier_slot(verifier_number, allocated)

		def try_spawn_and_retry():
			for remaining_attempts in reversed(range(attempts)):
				try:
					self._spawn_verifier_unsafe(verifier_number, allocated)
				except:
					if remaining_attempts == 0:
						self.free_slots.put(verifier_number)
						exc_info = sys.exc_info()
						self.logger.error("Failed to spawn verifier %d" % verifier_number, exc_info=exc_info)
						raise exc_info
					else:
						self.logger.info("Failed to spawn verifier %d, %d attempts remaining" % (verifier_number, remaining_attempts), exc_info=True)
					eventlet.sleep(10)
				else:
					break

		def unlock_link(greenlet):
			self._unlock_verifier_slot(verifier_number, allocated)

		eventlet.spawn(try_spawn_and_retry).link(unlock_link)

	def _trim_pool_size(self, old_max=None):
		new_min = self._get_min_unallocated()
		new_max = self._get_max_verifiers()

		if old_max is None:
			old_max = new_max

		for i in xrange(new_min, old_max):
			if i >= new_max and i in set(self.free_slots.queue):
				self.to_remove_free.add(i)
			elif i in self.unallocated_slots:
				self.unallocated_slots.remove(i)
				self.remove_verifier(i)

	def _increase_pool_size(self):
		new_max = self._get_max_verifiers()
		all_slots = set(list(set(self.free_slots.queue) - self.to_remove_free) + self.unallocated_slots + self.allocated_slots + self.to_unallocate + self.to_allocate)

		for i in xrange(new_max):
			if i not in all_slots:
				self.free_slots.put(i)

	def _fill_to_min_unallocated(self):
		num_to_fill = self._get_min_unallocated() - len(self.unallocated_slots) - len(self.to_unallocate)
		for i in xrange(num_to_fill):
			try:
				free = self.get_first_free(block=False)
			except queue.Empty:
				pass
			else:
				self._spawn_verifier_multiple_attempts(free, allocated=False)

	def spawn_verifier(self, verifier_number):
		raise NotImplementedError()

	def remove_verifier(self, verifier_number):
		verifier = self.verifiers[verifier_number]
		del self.verifiers[verifier_number]
		verifier.teardown()


class VirtualMachineVerifierPool(VerifierPool):
	def __init__(self, virtual_machine_class, max_verifiers=None, min_unallocated=None, uri_translator=None):
		self.virtual_machine_class = virtual_machine_class
		super(VirtualMachineVerifierPool, self).__init__(max_verifiers, min_unallocated, uri_translator)

	def spawn_verifier(self, verifier_number):
		virtual_machine = self.spawn_virtual_machine(verifier_number)
		virtual_machine.wait_until_ready()
		return BuildVerifier(CloudBuildCore(virtual_machine, self.uri_translator))

	def spawn_virtual_machine(self, virtual_machine_number):
		return self.virtual_machine_class.from_id_or_construct(virtual_machine_number)


class DockerVirtualMachineVerifierPool(VirtualMachineVerifierPool):
	def __init__(self, virtual_machine_class, max_verifiers=None, min_unallocated=None, uri_translator=None):
		super(DockerVirtualMachineVerifierPool, self).__init__(virtual_machine_class, max_verifiers, min_unallocated, uri_translator)

	def spawn_virtual_machine(self, virtual_machine_number):
		virtual_machine = super(DockerVirtualMachineVerifierPool, self).spawn_virtual_machine(virtual_machine_number)
		return DockerVm(virtual_machine)

	def put(self, verifier):
		verifier.rebuild()
		return super(DockerVirtualMachineVerifierPool, self).put(verifier)
