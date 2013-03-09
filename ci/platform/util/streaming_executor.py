import collections
import fcntl
import os

from subprocess import Popen, PIPE, STDOUT

from eventlet.green import select
from eventlet.timeout import Timeout


class StreamingExecutor(object):
	def execute(self, command, output_handler=None, cwd=None, env={}, timeout=None, **kwargs):
		env = dict(os.environ.copy(), **env)
		process = Popen(command, stdout=PIPE, stderr=STDOUT, cwd=cwd, env=env)
		try:
			with Timeout(timeout):
				self._handle_output(process, output_handler)
		except Timeout:
			returncode = 127
		else:
			returncode = process.wait()
		finally:
			output = "\n".join(self._output_lines)
		return CommandResults(returncode, output)

	def _handle_output(self, process, line_handler):
		self._output_lines = list()
		self._unbuffer_stream(process.stdout)
		line_number = 1
		line = ''
		while True:
			returncode = process.poll()  # it is important to check this before output, to prevent lost output
			ready_read, ready_write, ready_xlist = select.select([process.stdout], [], [], 0.05)  # short timeout
			if ready_read:
				read_lines = {}
				new_output = process.stdout.read()
				if new_output == '':
					break
				for char in new_output:
					if char == '\n':
						read_lines[line_number] = line
						line = ''
						line_number += 1
					else:
						line = line + char
				if char != '\n':
					read_lines[line_number] = line
				if read_lines:
					self._handle_lines(line_handler, read_lines)
			elif returncode is not None:  # backgrounding processes will cause readline to wait forever, but sets a return code
				break
		if hasattr(line_handler, 'close'):
			line_handler.close()
		return self._output_lines

	def _handle_lines(self, line_handler, read_lines):
		for line_number, line in sorted(read_lines.items()):
			if len(self._output_lines) < line_number:
				self._output_lines.append(line)
			else:
				self._output_lines[line_number - 1] = line
		if line_handler:
			line_handler.append(read_lines)

	def _unbuffer_stream(self, stream):
		fd = stream.fileno()
		fl = fcntl.fcntl(fd, fcntl.F_GETFL)
		fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)


CommandResults = collections.namedtuple(
	"CommandResults", ["returncode", "output"])
