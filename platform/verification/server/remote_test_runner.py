# test_runner.py - Runs remote tests for the verification server

"""This file contains the logic required to run tests on a vagrant vm.
"""

import os

from bs4 import BeautifulSoup
from build_command import BuildCommand


class VagrantNoseCommand(BuildCommand):
	"""Simple nose implementation for running tests on a vagrant vm
	"""
	def __init__(self, vagrant):
		self.vagrant = vagrant

	def run(self):
		self.vagrant.ssh_call("find /home/vagrant/source -name \"tests\" |" +
				"xargs nosetests  --with-xunit --xunit-file=/vagrant/nosetests.xml")
		test_results = XunitParser().parse_file(
				os.path.join(self.vagrant.get_vm_directory(), "nosetests.xml"))
		return self._compute_return_code(test_results)

	def _compute_return_code(self, test_results):
		errors = 0
		if test_results:
			for suite in test_results:
				errors = errors + suite.errors + suite.failures
		return test_results


class XunitParser(object):
	"""Simple parser which converts xunit xml output to a python
	heirarchical dictionary structure
	"""
	def __init__(self):
		pass

	def parse(self, xml):
		soup = BeautifulSoup(xml)
		suites = []
		for suite in soup.suite:
			suites.append(self._parse_suite(suite))
		return suites

	def parse_file(self, file_name):
		if not os.path.exists(file_name):
			return None
		with open(file_name) as file:
			return self.parse(file.read())

	def _parse_suite(self, suite):
		name = suite['name']
		tests = suite['tests']
		errors = suite['errors']
		failures = suite['failures']
		skip = suite['skip']
		testcases = []
		for testcase in suite.testcase:
			testcases.append(self._parse_testcase(testcase))
		return {'name': name,
				'tests': tests,
				'errors': errors,
				'failures': failures,
				'skip': skip,
				'testcases': testcases}

	def _parse_testcase(self, testcase):
		classname = testcase['classname']
		name = testcase['name']
		time = testcase['time']
		if testcase.error:
			error = self._parse_error(self, testcase.error)
		else:
			error = None
		return {'classname': classname,
				'name': name,
				'time': time,
				'error': error}

	def _parse_error(self, error):
		error_type = error['type']
		error_message = error['message']
		error_trace = error.contents[1]
		return {'type': error_type,
				'message': error_message,
				'trace': error_trace}
