import time

from nose.tools import *
from util.test import BaseUnitTest
from util.streaming_executor import StreamingExecutor


class StreamingExecutorTests(BaseUnitTest):
	def setUp(self):
		pass

	def tearDown(self):
		pass

	def test_execute_command(self):
		start_time = time.time()
		results = StreamingExecutor.execute(['echo', 'hi'])
		assert_equal(0, results.returncode)
		assert_equal('hi', results.output)
		assert_true(time.time() - start_time < 1)

	def test_execute_two_commands(self):
		start_time = time.time()
		results = StreamingExecutor.execute(['bash', '-c', 'echo hi; echo bye'])
		assert_equal(0, results.returncode)
		assert_equal('hi\nbye', results.output)
		assert_true(time.time() - start_time < 1)

	def test_execute_bad(self):
		start_time = time.time()
		results = StreamingExecutor.execute(['cat', '/'])
		assert_equal(1, results.returncode)
		assert_equal('cat: /: Is a directory', results.output)
		assert_true(time.time() - start_time < 1)

	def test_execute_background(self):
		start_time = time.time()
		results = StreamingExecutor.execute(['bash', '-c', '(sleep 2)&'])
		assert_equal(0, results.returncode)
		assert_equal('', results.output)
		assert_true(time.time() - start_time < 1)

	def test_streaming(self):
		strings_to_print = ['hello', 'one two three', 'Herp Im a Derp']
		output_handler = TestOutputHandler(strings_to_print)
		echo_command = ';'.join(map(lambda s: 'echo %s' % s, strings_to_print))
		results = StreamingExecutor.execute(['bash', '-c', echo_command], output_handler=output_handler)
		assert_equal(0, results.returncode)
		assert_equal('\n'.join(strings_to_print), results.output)
		assert_equal(output_handler.expected_lines, output_handler.received_lines)

	def test_cwd(self):
		results = StreamingExecutor.execute(['pwd'], cwd='/')
		assert_equal(0, results.returncode)
		assert_equal('/', results.output)

		results = StreamingExecutor.execute(['pwd'], cwd='/bin')
		assert_equal(0, results.returncode)
		assert_equal('/bin', results.output)

	def test_env(self):
		results = StreamingExecutor.execute(['bash', '-c', 'echo $test_var_1; echo $test_var_2'], env={'test_var_1': 'one', 'test_var_2': 'two'})
		assert_equal(0, results.returncode)
		assert_equal('one\ntwo', results.output)

	def test_timeout(self):
		results = StreamingExecutor.execute(['sleep', '1'], timeout=0.1)
		assert_equal(127, results.returncode)
		assert_equal('', results.output)


class TestOutputHandler(object):
	def __init__(self, expected_lines):
		self.expected_lines = expected_lines
		self.received_lines = []
		for i in range(len(self.expected_lines)):
			self.received_lines.append(None)

	def append(self, line_number, line):
		assert_true(line_number < len(self.expected_lines) + 1)
		assert_equal(self.expected_lines[line_number - 1], line)
		self.received_lines[line_number - 1] = line
