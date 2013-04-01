import os

import eventlet

from eventlet import queue

from build_core import CloudBuildCore
from build_verifier import BuildVerifier
from settings.verification_server import VerificationServerSettings


class VerifierPool(object):
	def __init__(self, max_verifiers=None, min_unallocated=None, uri_translator=None):
		self.max_verifiers = max_verifiers
		self.min_unallocated = min_unallocated

		max_verifiers = self._get_max_verifiers()
		min_unallocated = self._get_min_unallocated()
		assert max_verifiers >= min_unallocated

		self.uri_translator = uri_translator
		self._current_max_verifiers = max_verifiers
		self.free_slots = queue.Queue()
		for i in range(max_verifiers):
			self.free_slots.put(i)
		self.unallocated_slots = []
		self.allocated_slots = []
		self.verifiers = {}

		self._fill_to_min_unallocated()

	def _get_max_verifiers(self):
		return self.max_verifiers if self.max_verifiers is not None else VerificationServerSettings.max_virtual_machine_count

	def _get_min_unallocated(self):
		return self.min_unallocated if self.min_unallocated is not None else VerificationServerSettings.static_pool_size

	def teardown(self):
		for i in self.unallocated_slots + self.allocated_slots:
			self.remove_verifier(i)

	def get(self):
		unallocated = self.get_first_unallocated()

		if unallocated is not None:
			self.allocated_slots.append(unallocated)
			return self.verifiers[unallocated]
		free = self.get_first_free()
		try:
			self._spawn_verifier(free)
		except:
			self.free_slots.put(free)
			raise
		return self.verifiers[free]

	def put(self, verifier):
		slot = self._get_slot(verifier)
		self.allocated_slots.remove(slot)
		self.unallocated_slots.append(slot)

	def remove(self, verifier):
		slot = self._get_slot(verifier)
		del self.verifiers[slot]
		if slot in self.unallocated_slots:
			self.unallocated_slots.remove(slot)
		elif slot in self.allocated_slots:
			self.allocated_slots.remove(slot)

		# Abandon slots that are higher than the current cap
		if self._get_max_verifiers() > slot:
			self.free_slots.put(slot)
		self._fill_to_min_unallocated()

	def _get_slot(self, verifier):
		for slot, v in self.verifiers.items():
			if v == verifier:
				return slot
		return None

	def get_first_unallocated(self):
		if self.unallocated_slots:
			unallocated_slot = self.unallocated_slots.pop()
			self._fill_to_min_unallocated()
			return unallocated_slot
		return None

	def get_first_free(self, block=True):
		return self.free_slots.get(block)

	def _spawn_verifier(self, verifier_number, allocated=True):
		assert verifier_number not in self.verifiers
		self.verifiers[verifier_number] = self.spawn_verifier(verifier_number)
		if allocated:
			self.allocated_slots.append(verifier_number)
		else:
			self.unallocated_slots.append(verifier_number)

	def _spawn_verifier_multiple_attempts(self, verifier_number, allocated=True, attempts=10):
		for remaining_attempts in reversed(range(attempts)):
			try:
				self._spawn_verifier(verifier_number, allocated=False)
			except:
				if remaining_attempts == 0:
					self.free_slots.put(verifier_number)
					raise
				eventlet.sleep(10)
			else:
				break

	def _fill_to_min_unallocated(self):
		new_max = self._get_max_verifiers()
		for i in range(self._current_max_verifiers, new_max):
			self.free_slots.put(i)
			self._current_max_verifiers += 1

		num_to_fill = self._get_min_unallocated() - len(self.unallocated_slots)
		for i in range(num_to_fill):
			try:
				free = self.get_first_free(block=False)
			except queue.Empty:
				pass
			else:
				self._spawn_verifier_multiple_attempts(free, allocated=False)

	def spawn_verifier(self, verifier_number):
		raise NotImplementedError()

	def remove_verifier(self, verifier_number):
		self.verifiers[verifier_number].teardown()
		del self.verifiers[verifier_number]


class VirtualMachineVerifierPool(VerifierPool):
	def __init__(self, virtual_machine_class, directory, max_verifiers=None, min_unallocated=None, uri_translator=None):
		self.virtual_machine_class = virtual_machine_class
		self.directory = directory
		super(VirtualMachineVerifierPool, self).__init__(max_verifiers, min_unallocated, uri_translator)

	def spawn_verifier(self, verifier_number):
		virtual_machine = self.spawn_virtual_machine(verifier_number)
		return BuildVerifier(CloudBuildCore(virtual_machine, self.uri_translator))

	def spawn_virtual_machine(self, virtual_machine_number):
		vm_directory = os.path.join(self.directory, str(virtual_machine_number))
		return self.virtual_machine_class.from_directory_or_construct(vm_directory)
