import shutil
import os


class VirtualMachineCleanupTool(object):
	def __init__(self, directory, vm_class):
		self.directory = directory
		self.vm_class = vm_class

	def cleanup(self, filesystem=True):
		try:
			for directory in (directory for directory in os.listdir(self.directory) if os.path.isdir(directory) and not directory.endswith('log')):
				try:
					vm = self.vm_class.from_directory(directory)
					vm.delete() if vm else None
					if filesystem:
						shutil.rmtree(directory)
				except:
					pass
		except:
			pass
