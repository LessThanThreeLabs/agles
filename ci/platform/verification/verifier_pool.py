import os

from eventlet import queue

from build_core import CloudBuildCore
from build_verifier import BuildVerifier


class VerifierPool(object):
	ALLOCATED = True
	UNALLOCATED = False

	def __init__(self, max_verifiers, uri_translator=None):
		self.max_verifiers = max_verifiers
		self.uri_translator = uri_translator
		self.free_slots = queue.Queue()
		for x in range(max_verifiers):
			self.free_slots.put(x)
		self.unallocated_slots = []
		self.allocated_slots = []
		self.verifiers = {}

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

	def _get_slot(self, verifier):
		for slot, v in self.verifiers.items():
			if v == verifier:
				return slot

	def get_first_unallocated(self):
		if self.unallocated_slots:
			return self.unallocated_slots.pop()

	def get_first_free(self):
		return self.free_slots.get()

	def _spawn_verifier(self, verifier_number, allocated=True):
		assert verifier_number not in self.verifiers
		if allocated:
			self.allocated_slots.append(verifier_number)
		else:
			self.unallocated_slots.append(verifier_number)
		self.verifiers[verifier_number] = self.spawn_verifier(verifier_number)

	def spawn_verifier(self, verifier_number):
		raise NotImplementedError()

	def remove_verifier(self, verifier_number):
		self.verifiers[verifier_number].teardown()
		del self.verifiers[verifier_number]


class VirtualMachineVerifierPool(VerifierPool):
	def __init__(self, virtual_machine_class, directory, max_verifiers, uri_translator=None):
		super(VirtualMachineVerifierPool, self).__init__(max_verifiers, uri_translator)
		self.virtual_machine_class = virtual_machine_class
		self.directory = directory

	def spawn_verifier(self, verifier_number):
		virtual_machine = self.spawn_virtual_machine(verifier_number)
		virtual_machine.wait_until_ready()
		return BuildVerifier(CloudBuildCore(virtual_machine, self.uri_translator))

	def spawn_virtual_machine(self, virtual_machine_number):
		return self.virtual_machine_class.from_directory_or_construct(os.path.join(self.directory, str(virtual_machine_number)))
