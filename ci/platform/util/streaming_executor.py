import collections
import os

from subprocess import Popen, PIPE, STDOUT

from eventlet.green import select


class StreamingExecutor(object):
	@classmethod
	def execute(cls, command, output_handler=None, cwd=None, env={}, **kwargs):
		env = dict(os.environ.copy(), **env)
		process = Popen(command, stdout=PIPE, stderr=STDOUT, cwd=cwd, env=env)
		output_lines = cls._handle_stream(process.stdout, output_handler)
		output = "\n".join(output_lines)
		returncode = process.wait()
		return CommandResults(returncode, output)

	@classmethod
	def _handle_stream(cls, stream, line_handler):
		lines = list()
		while True:
			select.select([stream], [], [])
			line = stream.readline()
			if line == "":
				break
			line = line.rstrip()
			lines.append(line)
			if line_handler:
				line_handler.append(len(lines), line)
		return lines


CommandResults = collections.namedtuple(
	"CommandResults", ["returncode", "output"])
