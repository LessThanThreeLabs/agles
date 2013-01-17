import collections
import os

from subprocess import Popen, PIPE, STDOUT

from eventlet.green import select
from eventlet.timeout import Timeout


class StreamingExecutor(object):
	@classmethod
	def execute(cls, command, output_handler=None, cwd=None, env={}, timeout=None, **kwargs):
		env = dict(os.environ.copy(), **env)
		process = Popen(command, stdout=PIPE, stderr=STDOUT, cwd=cwd, env=env)
		try:
			with Timeout(timeout):
				cls._handle_output(process, output_handler)
		except Timeout:
			returncode = 127
		else:
			returncode = process.wait()
		finally:
			output = "\n".join(cls._output_lines)
			del cls._output_lines
		return CommandResults(returncode, output)

	@classmethod
	def _handle_output(cls, process, line_handler):
		cls._output_lines = list()
		while True:
			returncode = process.poll()  # it is important to check this before output, to prevent lost output
			ready_read, ready_write, ready_xlist = select.select([process.stdout], [], [], 0.01)  # short timeout
			if ready_read:
				line = process.stdout.readline()
				if line == "":
					break
				line = line.rstrip()
				cls._output_lines.append(line)
				if line_handler:
					line_handler.append(len(cls._output_lines), line)
			elif returncode is not None:  # backgrounding processes will cause readline to wait forever, but sets a return code
				break
		return cls._output_lines


CommandResults = collections.namedtuple(
	"CommandResults", ["returncode", "output"])
