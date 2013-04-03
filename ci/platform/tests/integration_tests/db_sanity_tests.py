from alembic.command import downgrade, upgrade, stamp
from alembic.config import Config
from alembic.script import ScriptDirectory
from nose.tools import *

from util.test import BaseIntegrationTest
from util.test import fake_data_generator

ALEMBIC_CFG_PATH = "alembic.ini"


class DbSanityTest(BaseIntegrationTest):
	def setUp(self):
		super(DbSanityTest, self).setUp()
		self.alembic_cfg = Config(ALEMBIC_CFG_PATH)

	def test_full_migration_down_up_filled(self):
		self._seed_db()
		self._downgrade_then_upgrade()

	def test_full_migration_down_up_empty(self):
		self._downgrade_then_upgrade()

	def test_most_recent_migration(self):
		self._seed_db()
		sd = ScriptDirectory.from_config(self.alembic_cfg)
		head_sha = sd.get_current_head()
		stamp(self.alembic_cfg, head_sha)

		downgrade(self.alembic_cfg, '-1')
		upgrade(self.alembic_cfg, '+1')

	def _downgrade_then_upgrade(self):
		sd = ScriptDirectory.from_config(self.alembic_cfg)
		head_sha = sd.get_current_head()
		stamp(self.alembic_cfg, head_sha)

		initial_rev = list(sd.iterate_revisions('head', 'base'))[-1].revision
		downgrade(self.alembic_cfg, initial_rev)
		upgrade(self.alembic_cfg, head_sha)

	def _seed_db(self):
		generator = fake_data_generator.SchemaDataGenerator()
		generator.generate(num_repos=3, num_repo_stores=1, num_users=3, num_commits=3)
