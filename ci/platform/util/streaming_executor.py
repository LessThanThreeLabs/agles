import collections
import fcntl
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
		stream = process.stdout
		fd = stream.fileno()
		fl = fcntl.fcntl(fd, fcntl.F_GETFL)
		fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
		line_number = 1
		line = ''
		while True:
			returncode = process.poll()  # it is important to check this before output, to prevent lost output
			ready_read, ready_write, ready_xlist = select.select([process.stdout], [], [], 0.05)  # short timeout
			if ready_read:
				new_output = stream.read()
				if new_output == '':
					break
				for char in new_output:
					if char == '\n':
						cls._handle_line(line_handler, line_number, line)
						line = ''
						line_number += 1
					else:
						line = line + char
				if char != '\n':
					cls._handle_line(line_handler, line_number, line)
			elif returncode is not None:  # backgrounding processes will cause readline to wait forever, but sets a return code
				break
		return cls._output_lines

	@classmethod
	def _handle_line(cls, line_handler, line_number, line):
		if len(cls._output_lines) < line_number:
			cls._output_lines.append(line)
		else:
			cls._output_lines[line_number - 1] = line
		if line_handler:
			line_handler.append(line_number, line)


CommandResults = collections.namedtuple(
	"CommandResults", ["returncode", "output"])
