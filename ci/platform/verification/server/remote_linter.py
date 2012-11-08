# remote_linter.py - Runs remote linting for the verification server

#"""This file contains the logic required to run linting on a vagrant vm.
#"""

# import re

# from vagrant.vagrant_command import VagrantCommand


# class VagrantLintingCommand(VagrantCommand):
# 	"""Simple pylint implementation for running static python analysis
# 	on a vagrant vm
# 	"""
# 	def __init__(self, path):
# 		self.path = path or ''

# 	def run(self, vagrant_wrapper, output_handler):
# 		source_path = "/home/vagrant/source/" + self.path
# 		command = "source .python.sh; find " + source_path + " -name \"__init__.py\" | sed -e s/\\\\/__init__.py$// | xargs pylint --reports=n"
# 		results = vagrant_wrapper.ssh_call(command, output_handler)
# 		lint_parser = LintParser()
# 		pylint_issues = lint_parser.parse_pylint(results.stdout)
# 		errors = lint_parser.get_errors(pylint_issues)
# 		return len(errors)


# class LintParser(object):
# 	"""Simple parser which converts pylint basic output into a python
# 	dictionary map
# 	"""
# 	ISSUE_TYPES = ['C', 'R', 'I', 'W', 'E', 'F']

# 	def __init__(self):
# 		pass

# 	def get_new_issue_map(self):
# 		issues = {}
# 		for issue_type in self.ISSUE_TYPES:
# 			issues[issue_type] = []
# 		return issues

# 	def parse_pylint(self, pylint_output):
# 		issues = self.get_new_issue_map()
# 		for line in pylint_output.splitlines():
# 			match = re.match("([a-zA-Z]):\s*(.*)", line)
# 			if match != None:
# 				issue_type = match.group(1)
# 				details = match.group(2)
# 				issues[issue_type].append(details)
# 		return issues

# 	def get_errors(self, issue_map):
# 		errors = issue_map['E']
# 		errors.extend(issue_map['F'])
# 		return errors
