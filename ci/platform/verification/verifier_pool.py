import os

from eventlet import queue

from build_core import CloudBuildCore
from build_verifier import BuildVerifier


class VerifierPool(object):
	def __init__(self, max_verifiers, min_unallocated=1, uri_translator=None):
		assert max_verifiers >= min_unallocated

		self.max_verifiers = max_verifiers
		self.min_unallocated = min_unallocated
		self.uri_translator = uri_translator
		self.free_slots = queue.Queue()
		for i in range(max_verifiers):
			self.free_slots.put(i)
		self.unallocated_slots = []
		self.allocated_slots = []
		self.verifiers = {}

		self._fill_to_min_unallocated()

	def teardown(self):
		for i in self.unallocated_slots + self.allocated_slots:
			self.remove_verifier(i)

	def get(self):
		unallocated = self.get_first_unallocated()

		if unallocated:
			self.allocated_slots.append(unallocated)
			return self.verifiers[unallocated]
		free = self.get_first_free()
		self._spawn_verifier(free)
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

	def _fill_to_min_unallocated(self):
		num_to_fill = self.min_unallocated - len(self.unallocated_slots)
		for i in range(num_to_fill):
			try:
				free = self.get_first_free(block=False)
			except queue.Empty:
				pass
			else:
				self._spawn_verifier(free, allocated=False)

	def spawn_verifier(self, verifier_number):
		raise NotImplementedError()

	def remove_verifier(self, verifier_number):
		self.verifiers[verifier_number].teardown()
		del self.verifiers[verifier_number]


class VirtualMachineVerifierPool(VerifierPool):
	def __init__(self, virtual_machine_class, directory, max_verifiers, min_unallocated=1, uri_translator=None):
		self.virtual_machine_class = virtual_machine_class
		self.directory = directory
		super(VirtualMachineVerifierPool, self).__init__(max_verifiers, min_unallocated, uri_translator)

	def spawn_verifier(self, verifier_number):
		virtual_machine = self.spawn_virtual_machine(verifier_number)
		return BuildVerifier(CloudBuildCore(virtual_machine, self.uri_translator))

	def spawn_virtual_machine(self, virtual_machine_number):
		vm_directory = os.path.join(self.directory, str(virtual_machine_number))
		return self.virtual_machine_class.from_directory_or_construct(vm_directory)
