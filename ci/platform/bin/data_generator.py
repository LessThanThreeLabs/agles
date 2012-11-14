#!/usr/bin/python
import argparse
import hashlib
import random
import string
import time

from database import schema
from database.engine import ConnectionFactory
from util.permissions import RepositoryPermissions

NUM_REPOS = 3
REPOSITORIES_PATH = 'repos'


class SchemaDataGenerator(object):
	def __init__(self, seed=None):
		random.seed(seed)

	def generate(self):
		schema.reseed_db()
		with ConnectionFactory.get_sql_connection() as conn:
			repos = dict()
			repo_hashes = []
			for repostore in range(random.randint(1, 3)):
				ins_repostore = schema.repostore.insert().values(uri="repostore_%d" % repostore, repositories_path=REPOSITORIES_PATH, host_name=hashlib.sha1(str(repostore)).hexdigest())
				repostore_id = conn.execute(ins_repostore).inserted_primary_key[0]

				for repo in range(random.randint(1, NUM_REPOS)):
					ins_repo = schema.repo.insert().values(name="repo_%d" % repo, hash="hash_%d,%d" % (repostore, repo),
						repostore_id=repostore_id, default_permissions=RepositoryPermissions.RW)
					repo_id = conn.execute(ins_repo).inserted_primary_key[0]
					ins_map = schema.uri_repo_map.insert().values(uri="uri_%d_%d" % (repostore, repo), repo_id=repo_id)
					conn.execute(ins_map)
					repos[repo_id] = 0
					repo_hashes.append("hash_%d,%d" % (repostore, repo))

			for user in range(random.randint(1, 10)):
				ins_user = schema.user.insert().values(first_name="firstname_%d" % user, last_name="lastname_%d" % user, email="%d@b.com" % user,
					password_hash=hashlib.sha512(str(user)).digest(), salt='a'*16)
				user_id = conn.execute(ins_user).inserted_primary_key[0]

				repo_hash = random.choice(repo_hashes)
				permissions = random.choice(RepositoryPermissions.valid_permissions())
				ins_permission = schema.permission.insert().values(user_id=user_id, repo_hash=repo_hash, permissions=permissions)
				conn.execute(ins_permission)

				for commit in range(random.randint(1, 100)):
					repo_id = random.choice(repos.keys())
					repo_hash_query = schema.repo.select().where(schema.repo.c.id==repo_id)
					repo_hash = conn.execute(repo_hash_query).first()[schema.repo.c.hash]
					repos[repo_id] = repos[repo_id] + 1
					ins_commit = schema.commit.insert().values(repo_hash=repo_hash, user_id=user_id,
						message="message_%d" % commit, timestamp=random.randint(1, int(time.time())))
					commit_id = conn.execute(ins_commit).inserted_primary_key[0]
					ins_change = schema.change.insert().values(commit_id=commit_id, merge_target="target_%d" % commit,
						number=repos[repo_id], status=random.randint(0, 3),
						start_time=int(time.time()) + random.randint(-10000, 10000),
						end_time=int(time.time()) + random.randint(10000, 12000))
					change_id = conn.execute(ins_change).inserted_primary_key[0]
					ins_build = schema.build.insert().values(change_id=change_id, is_primary=True, status=random.randint(0, 3),
						start_time=int(time.time()) + random.randint(-10000, 10000),
						end_time=int(time.time()) + random.randint(10000, 12000))
					build_id = conn.execute(ins_build).inserted_primary_key[0]
					ins_map = schema.build_commits_map.insert().values(build_id=build_id, commit_id=commit_id)
					conn.execute(ins_map)

					for console_type in range(2):
						ins_console = schema.build_console.insert().values(build_id=build_id, type=console_type,
							subcategory="category", console_output=self.generate_console_output())
						conn.execute(ins_console)

	def generate_console_output(self):
		output = ""
		for line_num in range(random.randint(20, 1000)):
			output = output + ''.join(random.choice(string.ascii_letters + string.digits + ' ') for x in range(random.randint(1, 100))) + "\n"
		return output


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-s", "--seed",
		help="Random seed to be used")
	parser.set_defaults(seed=None)
	args = parser.parse_args()

	generator = SchemaDataGenerator(args.seed)
	generator.generate()

main()
