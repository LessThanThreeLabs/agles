import binascii
import hashlib
import random
import string
import time

from database import schema
from database.engine import ConnectionFactory
from model_server.system_settings.update_handler import SystemSettingsUpdateHandler

SALT = 'GMZhGiZU4/JYE3NlmCZgGA=='

ADMIN_EMAIL = 'admin@admin.com'
ADMIN_PASSWORD = 'admin123'

USER_EMAIL = 'user@user.com'
USER_PASSWORD = 'user123'

REPOSITORIES_PATH = 'repos'

FAKE_XUNIT_RESULTS = ['<?xml version="1.0" encoding="UTF-8"?><testsuite name="nosetests" tests="9" errors="0" failures="1" skip="0"><testcase classname="pathgen_tests.ShellTest" name="test_directory_treeify" time="0.000"></testcase><testcase classname="pathgen_tests.ShellTest" name="test_to_path" time="0.000"></testcase><testcase classname="remote_command_tests.RemoteCommandTest" name="test_xunit_function_replacement" time="0.513"><failure type="exceptions.AssertionError" message="False is not true"><![CDATA[Traceback (most recent call last):' +
  'File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/unittest/case.py", line 327, in run' +
'    testMethod()' +
'  File "/Users/jchu/code/koality/core/ci/platform/tests/unit_tests/remote_command_tests.py", line 9, in test_xunit_function_replacement' +
'    self._xunit_function_replacement_for_step({"mycommand": {"script": "true", "xunit": "some/path"}})' +
'  File "/Users/jchu/code/koality/core/ci/platform/tests/unit_tests/remote_command_tests.py", line 21, in _xunit_function_replacement_for_step' +
'    assert_true(False)' +
'  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/unittest/case.py", line 420, in assertTrue' +
'    raise self.failureException(msg)' +
'AssertionError: False is not true' +
']]></failure></testcase><testcase classname="shell_tests.ShellTest" name="test_command_mutation" time="0.001"></testcase><testcase classname="shell_tests.ShellTest" name="test_invalid_command" time="0.000"></testcase><testcase classname="virtual_machine_util_tests.VirtualMachineUtilTest" name="test_add" time="0.000"></testcase><testcase classname="virtual_machine_util_tests.VirtualMachineUtilTest" name="test_image_version_comparison" time="0.000"></testcase><testcase classname="virtual_machine_util_tests.VirtualMachineUtilTest" name="test_image_version_equality" time="0.000"></testcase><testcase classname="virtual_machine_util_tests.VirtualMachineUtilTest" name="test_to_string" time="0.000"></testcase></testsuite>',
'<?xml version="1.0" encoding="UTF-8" ?>' +
'<testsuites>' +
'<testsuite name="accountInformationValidator" errors="0" tests="6" failures="0" time="0.002" timestamp="2013-08-15T14:10:47">' +
  '<testcase classname="accountInformationValidator" name="should correctly check email validity" time="0" />' +
  '<testcase classname="accountInformationValidator" name="should correctly check password validity" time="0.001"/>' +
  '<testcase classname="accountInformationValidator" name="should correctly check first name validity" time="0">' +
	'<system-err>some error message</system-err>' +
  '</testcase>' +
  '<testcase classname="accountInformationValidator" name="should correctly check last name validity" time="0"></testcase>' +
  '<testcase classname="accountInformationValidator" name="should correctly check ssh alias validity" time="0"></testcase>' +
  '<testcase classname="accountInformationValidator" name="should correctly check ssh key validity" time="0.001"></testcase>' +
'</testsuite>' +
'</testsuites>',
'<?xml version="1.0" encoding="UTF-8" ?>' +
'<testsuites>' +
'<testsuite name="resourceHandler" errors="0" tests="0" failures="0" time="0" timestamp="2013-08-15T14:10:47">' +
'</testsuite>' +
'<testsuite name="resourceHandler.constructor" errors="0" tests="1" failures="1" time="0.001" timestamp="2013-08-15T14:10:47">' +
  '<testcase classname="resourceHandler.constructor" name="should only accept valid params" time="0.001"><failure message="collection failure">some failure here</failure></testcase>' +
'</testsuite>' +
'</testsuites>',
'<?xml version="1.0" encoding="UTF-8" ?>' +
'<testsuites>' +
'<testsuite name="systemSettingsInformationValidator" errors="0" tests="9" failures="0" time="0.002" timestamp="2013-08-15T14:10:47">' +
  '<testcase classname="systemSettingsInformationValidator" name="should correctly check domain name validity" time="0.001"></testcase>' +
  '<testcase classname="systemSettingsInformationValidator" name="should correctly check aws access key validity" time="0"></testcase>' +
  '<testcase classname="systemSettingsInformationValidator" name="should correctly check aws secret validity" time="0"></testcase>' +
  '<testcase classname="systemSettingsInformationValidator" name="should correctly check hp cloud access key validity" time="0"></testcase>' +
  '<testcase classname="systemSettingsInformationValidator" name="should correctly check hp cloud secret validity" time="0.001"></testcase>' +
  '<testcase classname="systemSettingsInformationValidator" name="should correctly check hp cloud tenant name validity" time="0"></testcase>' +
  '<testcase classname="systemSettingsInformationValidator" name="should correctly check num waiting instances validity" time="0"></testcase>' +
  '<testcase classname="systemSettingsInformationValidator" name="should correctly check max running instances validity" time="0"></testcase>' +
  '<testcase classname="systemSettingsInformationValidator" name="should correctly check bucket name validity" time="0"></testcase>' +
'</testsuite>' +
'</testsuites>']


class SchemaDataGenerator(object):
	def __init__(self, seed=None):
		random.seed(seed)

	def generate(self, num_repos=2, num_repo_stores=1, num_users=3, num_commits=20, num_exports=3):
		schema.reseed_db()
		hash = hashlib.sha512()
		hash.update(SALT)
		hash.update(ADMIN_PASSWORD.encode('utf8'))
		ins_admin = schema.user.insert().values(
			email="admin@admin.com",
			first_name="Admin",
			last_name="Admin",
			admin=True,
			password_hash=binascii.b2a_base64(hash.digest())[0:-1],
			salt=SALT,
			created=int(time.time())
		)

		with ConnectionFactory.get_sql_connection() as conn:
			self.admin_id = conn.execute(ins_admin).inserted_primary_key[0]
			repos = dict()
			repo_ids = []
			for repostore in range(num_repo_stores):
				ins_repostore = schema.repostore.insert().values(repositories_path=REPOSITORIES_PATH, ip_address=hashlib.sha1(str(repostore)).hexdigest())
				repostore_id = conn.execute(ins_repostore).inserted_primary_key[0]

				for repo in range(num_repos):
					ins_repo = schema.repo.insert().values(name="repo-%d" % repo, uri="koality-%d-%d.git" % (repostore, repo),
						repostore_id=repostore_id, forward_url="bogusurl", created=int(time.time()), type="git")
					repo_id = conn.execute(ins_repo).inserted_primary_key[0]
					repos[repo_id] = 0
					repo_ids.append(repo_id)

			for user in range(num_users):
				first_name = random.choice(['Jon', 'Jordan', 'Brian', 'Ryan', 'Andrey'])
				last_name = random.choice(['Chu', 'Potter', 'Bland', 'Scott', 'Kostov'])


				ins_user = schema.user.insert().values(first_name=first_name, last_name=last_name,
					email="%s%d@address.com" % (first_name[0] + last_name, user),
					password_hash=binascii.b2a_base64(hashlib.sha512(SALT + USER_PASSWORD.encode('utf8')).digest())[0:-1], salt=SALT, created=int(time.time()))
				user_id = conn.execute(ins_user).inserted_primary_key[0]

				repo_id = random.choice(repo_ids)
				for commit in range(num_commits):
					repo_id = random.choice(repos.keys())
					repo_id_query = schema.repo.select().where(schema.repo.c.id == repo_id)
					repo_id = conn.execute(repo_id_query).first()[schema.repo.c.id]
					repos[repo_id] += 1
					sha = ''.join(random.choice('0123456789abcdef') for x in range(40))
					commit_message = 'Jon %s while %s' % (random.choice(['ate', 'fell', 'exploded', 'watched tv']),
							random.choice(['listening to Selena Gomez\n\nBut only on MTV', 'chewing gum\n\nDouble the pleasure, double the fun', 'praying to Raptor Jesus']))
					ins_commit = schema.commit.insert().values(repo_id=repo_id, user_id=user_id,
						message=commit_message, timestamp=random.randint(1, int(time.time())), sha=sha)
					commit_id = conn.execute(ins_commit).inserted_primary_key[0]
					ins_change = schema.change.insert().values(commit_id=commit_id, repo_id=repo_id, merge_target="target-%d" % commit,
						number=repos[repo_id], verification_status=self.get_random_commit_status(), merge_status=self.get_random_merge_status(),
						create_time=int(time.time()) + random.randint(-10000, 10000),
						start_time=int(time.time()) + random.randint(-10000, 10000),
						end_time=int(time.time()) + random.randint(10000, 12000))
					change_id = conn.execute(ins_change).inserted_primary_key[0]
					ins_build = schema.build.insert().values(commit_id=commit_id, change_id=change_id,
						repo_id=repo_id, status=self.get_random_commit_status(),
						create_time=int(time.time()) + random.randint(-10000, 10000),
						start_time=int(time.time()) + random.randint(-10000, 10000),
						end_time=int(time.time()) + random.randint(10000, 12000))
					build_id = conn.execute(ins_build).inserted_primary_key[0]

					for console_type in ['compile', 'test']:
						ins_console = schema.build_console.insert().values(build_id=build_id, repo_id=repo_id, type=console_type,
							subtype="subtype", subtype_priority=0, start_time=int(time.time()))
						console_id = conn.execute(ins_console).inserted_primary_key[0]
						self.generate_console_output(conn, console_id)

						ins_console = schema.build_console.insert().values(build_id=build_id, repo_id=repo_id, type=console_type,
							subtype="subtype2", subtype_priority=1, start_time=int(time.time()))
						console_id = conn.execute(ins_console).inserted_primary_key[0]
						self.generate_console_output(conn, console_id)

						if console_type == 'test':
							for index in range(random.randint(0, 3)):
								ins_xunit = schema.xunit.insert().values(build_console_id=console_id, path='some/path/%d' % index, contents=FAKE_XUNIT_RESULTS[index])
								conn.execute(ins_xunit)

					for export_id in range(num_exports):
						conn.execute(schema.build_export_metadata.insert().values(build_id=build_id, uri='https://someuri/0/file_%s.jpg' % export_id, path='file_%s.jpg' % export_id))

			SystemSettingsUpdateHandler().initialize_deployment(1, True)

	def get_random_commit_status(self):
		return random.choice(['queued', 'running', 'passed', 'failed', 'skipped'])

	def get_random_merge_status(self):
		return random.choice(['passed', 'failed', None])

	def generate_console_output(self, sqlconn, console_id):
		console_output = schema.console_output

		for line_num in range(1, random.randint(100, 200)):
			output = ''.join(random.choice(string.ascii_letters + string.digits + ' ') for x in range(random.randint(1, 100)))
			ins = console_output.insert().values(
				build_console_id=console_id,
				line_number=line_num,
				line=output
			)
			sqlconn.execute(ins)
