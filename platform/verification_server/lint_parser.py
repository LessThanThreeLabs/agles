import re


class LintParser(object):

	ISSUE_TYPES = ['C', 'R', 'W', 'E', 'F']

	def __init__(self):
		pass

	def get_new_issue_map(self):
		issues = {}
		for issue_type in self.ISSUE_TYPES:
			issues[issue_type] = []
		return issues

	def parse_pylint(self, pylint_output):
		issues = self.get_new_issue_map()
		for line in pylint_output.splitlines():
			match = re.match("([a-zA-Z]):\s*(.*)", line)
			if match != None:
				issue_type = match.group(1)
				details = match.group(2)
				issues[issue_type].append(details)
		return issues

	def get_errors(self, issue_map):
		errors = issue_map['E']
		errors.extend(issue_map['F'])
		return errors
