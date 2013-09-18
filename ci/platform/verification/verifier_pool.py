import eventlet
import sys

from build_core import CloudBuildCore
from build_verifier import BuildVerifier
from settings.verification_server import VerificationServerSettings
from util.log import Logged
from virtual_machine.docker import DockerVm


@Logged()
class VerifierPool(object):
	def __init__(self, max_running=None, min_ready=None, uri_translator=None):
		self.max_running = max_running
		self.min_ready = min_ready

		max_running = self._get_max_running()
		min_ready = self._get_min_ready()
		assert max_running >= min_ready

		self.uri_translator = uri_translator

		self.allocated_slots = []

		self.to_add_ready = []
		self.to_add_free = []

		self.verifiers = {}

		self.available = AvailableSlotQueue()

		self._initializing = False
		self._initialize_continuation = None

		self.reinitialize(max_running=max_running, min_ready=min_ready)

	def reinitialize(self, max_running=None, min_ready=None):
		# We use self._initializing as a lock for greenlets
		if not self._initializing:
			self._initializing = True
			self._reinitialize(max_running, min_ready)
			self._initializing = False
		else:
			self._initialize_continuation = lambda: self._reinitialize(max_running, min_ready)

	def _reinitialize(self, max_running=None, min_ready=None):
		old_max = self._get_max_running()
		self.max_running = max_running
		self.min_ready = min_ready
		self._trim_pool_size(old_max)
		self._increase_pool_size()
		self._fill_to_min_ready()
		if self._initialize_continuation:
			continuation = self._initialize_continuation
			self._initialize_continuation = None
			continuation()

	def _get_max_running(self):
		return self.max_running if self.max_running is not None else VerificationServerSettings.max_virtual_machine_count

	def _get_min_ready(self):
		return self.min_ready if self.min_ready is not None else VerificationServerSettings.static_pool_size

	def teardown(self):
		for i in self.available.get_ready_slots() + self.allocated_slots:
			self.remove_verifier(i)

	def get(self):
		def handle_ready(slot):
			self.allocated_slots.append(slot)
			self._fill_to_min_ready()
			return self.verifiers[slot]

		def handle_free(slot):
			try:
				self._spawn_verifier(slot)
			except:
				self.available.put_free(slot)
				raise
			return self.verifiers[slot]

		allocation, slot = self.available.get()

		if allocation == self.available.READY_PRIORITY:
			return handle_ready(slot)
		elif allocation == self.available.FREE_PRIORITY:
			return handle_free(slot)
		else:
			assert False, 'Found slot %s with allocation %s' % (slot, allocation)

	def put(self, verifier):
		slot = self._get_slot(verifier)
		self.available.put_ready(slot)
		self.allocated_slots.remove(slot)
		self._trim_pool_size()

	def remove(self, verifier):
		slot = self._get_slot(verifier)

		del self.verifiers[slot]
		# Abandon slots that are higher than the current cap
		if self._get_max_running() > slot:
			self.available.put_free(slot)

		if slot in self.available.get_ready_slots():
			self.available.remove_ready(slot)
		elif slot in self.allocated_slots:
			self.allocated_slots.remove(slot)

		self._fill_to_min_ready()

	def _get_slot(self, verifier):
		for slot, v in self.verifiers.items():
			if v == verifier:
				return slot
		return None

	def _lock_verifier_slot(self, verifier_number, allocated):
		assert verifier_number not in self.verifiers

		limbo_slots = self.to_add_free if allocated else self.to_add_ready
		limbo_slots.append(verifier_number)

	def _unlock_verifier_slot(self, verifier_number, allocated):
		limbo_slots = self.to_add_free if allocated else self.to_add_ready
		limbo_slots.remove(verifier_number)

	def _spawn_verifier_unsafe(self, verifier_number, allocated):
		self.verifiers[verifier_number] = self.spawn_verifier(verifier_number)
		if allocated:
			self.allocated_slots.append(verifier_number)
		else:
			if verifier_number >= self._get_max_running():
				self.remove_verifier(verifier_number)
			else:
				self.available.put_ready(verifier_number)

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
						exc_info = sys.exc_info()
						self.available.put_free(verifier_number)
						self.logger.error("Failed to spawn verifier %d" % verifier_number, exc_info=exc_info)
						raise exc_info[0], exc_info[1], exc_info[2]
					else:
						self.logger.info("Failed to spawn verifier %d, %d attempts remaining" % (verifier_number, remaining_attempts), exc_info=True)
					eventlet.sleep(10)
				else:
					break

		def unlock_link(greenlet):
			self._unlock_verifier_slot(verifier_number, allocated)

		eventlet.spawn(try_spawn_and_retry).link(unlock_link)

	def _trim_pool_size(self, old_max=None):
		new_min = self._get_min_ready()
		new_max = self._get_max_running()

		if old_max is None:
			old_max = new_max

		for i in xrange(new_max, old_max):
			if i in self.available.get_free_slots():
				self.available.remove_free(i)
			elif i in self.available.get_ready_slots():
				self.available.remove_ready(i)
				self.remove_verifier(i)

		ready_slots = self.available.get_ready_slots()
		excess_ready = len(ready_slots) - new_min
		for i in xrange(excess_ready):
			to_free = ready_slots.pop()
			self.available.remove_ready(to_free)
			self.remove_verifier(to_free)
			self.available.put_free(to_free)

	def _increase_pool_size(self):
		new_max = self._get_max_running()
		all_slots = set(self.available.get_free_slots() + self.available.get_ready_slots() + self.allocated_slots + self.to_add_ready + self.to_add_free)

		for i in xrange(new_max):
			if i not in all_slots:
				self.available.put_free(i)

	def _fill_to_min_ready(self):
		num_to_fill = self._get_min_ready() - len(self.available.get_ready_slots()) - len(self.to_add_ready)
		for i in xrange(num_to_fill):
			free_slots = self.available.get_free_slots()

			if free_slots:
				free = free_slots[0]
				self.available.remove_free(free)
				self._spawn_verifier_multiple_attempts(free, allocated=False)

	def spawn_verifier(self, verifier_number):
		raise NotImplementedError()

	def remove_verifier(self, verifier_number):
		verifier = self.verifiers[verifier_number]
		del self.verifiers[verifier_number]
		verifier.teardown()


class VirtualMachineVerifierPool(VerifierPool):
	def __init__(self, virtual_machine_class, max_running=None, min_ready=None, uri_translator=None):
		self.virtual_machine_class = virtual_machine_class
		super(VirtualMachineVerifierPool, self).__init__(max_running, min_ready, uri_translator)

	def spawn_verifier(self, verifier_number):
		virtual_machine = self.spawn_virtual_machine(verifier_number)
		try:
			virtual_machine.wait_until_ready()
		except:
			virtual_machine.delete()
			raise
		return BuildVerifier(CloudBuildCore(virtual_machine, self.uri_translator))

	def spawn_virtual_machine(self, virtual_machine_number):
		return self.virtual_machine_class.from_id_or_construct(virtual_machine_number)


class DockerVirtualMachineVerifierPool(VirtualMachineVerifierPool):
	def __init__(self, virtual_machine_class, max_running=None, min_ready=None, uri_translator=None):
		super(DockerVirtualMachineVerifierPool, self).__init__(virtual_machine_class, max_running, min_ready, uri_translator)

	def spawn_virtual_machine(self, virtual_machine_number):
		virtual_machine = super(DockerVirtualMachineVerifierPool, self).spawn_virtual_machine(virtual_machine_number)
		return DockerVm(virtual_machine)

	def put(self, verifier):
		try:
			verifier.rebuild()
		except:
			self.remove(verifier)
		else:
			return super(DockerVirtualMachineVerifierPool, self).put(verifier)


class AvailableSlotQueue(eventlet.queue.PriorityQueue):
	READY_PRIORITY = 0
	FREE_PRIORITY = 1

	def __init__(self):
		super(AvailableSlotQueue, self).__init__()
		self.consumer_queue = eventlet.queue.LightQueue()
		self._spawn_broker()

	def get(self):
		slot_event = eventlet.event.Event()
		self.consumer_queue.put(slot_event)
		return slot_event.wait()

	def put_ready(self, slot):
		return self._put_slot(self.READY_PRIORITY, slot)

	def put_free(self, slot):
		return self._put_slot(self.FREE_PRIORITY, slot)

	def remove_ready(self, slot):
		return self._remove_slot(self.READY_PRIORITY, slot)

	def remove_free(self, slot):
		return self._remove_slot(self.FREE_PRIORITY, slot)

	def get_ready_slots(self):
		return self._get_slots(self.READY_PRIORITY)

	def get_free_slots(self):
		return self._get_slots(self.FREE_PRIORITY)

	def _put_slot(self, slot_type, slot):
		return self.put((slot_type, slot))

	def _remove_slot(self, slot_type, slot):
		return self.queue.remove((slot_type, slot))

	def _get_slots(self, slot_type):
		return map(lambda item: item[1], filter(lambda item: item[0] == slot_type, self.queue))

	def _spawn_broker(self):
		def handle_consumers():
			while True:
				consumer = self.consumer_queue.get()
				resource = super(AvailableSlotQueue, self).get()
				consumer.send(resource)

		eventlet.spawn(handle_consumers)
