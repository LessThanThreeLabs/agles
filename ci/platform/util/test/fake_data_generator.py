import binascii
import hashlib
import random
import string
import time
import yaml
import base64

from database import schema
from database.engine import ConnectionFactory
from Crypto.Cipher import AES

SALT = 'GMZhGiZU4/JYE3NlmCZgGA=='

ADMIN_EMAIL = 'admin@admin.com'
ADMIN_PASSWORD = 'admin123'

USER_EMAIL = 'user@user.com'
USER_PASSWORD = 'user123'

REPOSITORIES_PATH = 'repos'

system_settings_cipher = AES.new(binascii.unhexlify('6B9945583AF2F9DE00D9EF1FABCCFA30CF84AA4E855E12DC448B277D7C65D90F'))


class SchemaDataGenerator(object):
	def __init__(self, seed=None):
		random.seed(seed)

	def generate(self, num_repos=2, num_repo_stores=1, num_users=2, num_commits=20):
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
						repostore_id=repostore_id, forward_url="bogusurl", publickey="somepublickey",
						privatekey="someprivatekey", created=int(time.time()))
					repo_id = conn.execute(ins_repo).inserted_primary_key[0]
					repos[repo_id] = 0
					repo_ids.append(repo_id)

			for user in range(num_users):
				ins_user = schema.user.insert().values(first_name="Firstname-%s" % chr(65 + user), last_name="Lastname-%s" % chr(65 + user),
					email="email-%s@address.com" % chr(65 + user),
					password_hash=binascii.b2a_base64(hashlib.sha512(SALT + USER_PASSWORD.encode('utf8')).digest())[0:-1], salt=SALT, created=int(time.time()))
				user_id = conn.execute(ins_user).inserted_primary_key[0]

				repo_id = random.choice(repo_ids)
				for commit in range(num_commits):
					repo_id = random.choice(repos.keys())
					repo_id_query = schema.repo.select().where(schema.repo.c.id == repo_id)
					repo_id = conn.execute(repo_id_query).first()[schema.repo.c.id]
					repos[repo_id] += 1
					ins_commit = schema.commit.insert().values(repo_id=repo_id, user_id=user_id,
						message="message-%d" % commit, timestamp=random.randint(1, int(time.time())), sha="thisissha")
					commit_id = conn.execute(ins_commit).inserted_primary_key[0]
					ins_change = schema.change.insert().values(commit_id=commit_id, repo_id=repo_id, merge_target="target-%d" % commit,
						number=repos[repo_id], status=self.get_random_commit_status(),
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

			self.set_deployment_as_initialized(conn)

	def get_random_commit_status(self):
		if random.randint(0, 100) > 25:
			return 'passed'
		else:
			return 'failed'

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

	def set_deployment_as_initialized(self, sqlconn):
		system_setting = schema.system_setting
		value = base64.encodestring(system_settings_cipher.encrypt(self._pad(yaml.safe_dump(True))))

		sqlconn.execute(system_setting.insert().values(
			resource="deployment",
			key="initialized",
			value=value
		))

	def _pad(self, setting):
		return setting + ((system_settings_cipher.block_size - len(setting) % system_settings_cipher.block_size) * '\n')
