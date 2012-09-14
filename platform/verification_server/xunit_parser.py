# xunit_parser.py - Converts xunit output to a python heirarchical data structure

from bs4 import BeautifulSoup


class XunitParser(object):
	def __init__(self):
		pass

	def parse(self, xml):
		soup = BeautifulSoup(xml)
		suites = []
		for suite in soup.suite:
			suites.append(self._parse_suite(suite))
		return suites

	def parse_file(self, file_name):
		with open(file_name) as file:
			self.parse(file.read())

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
