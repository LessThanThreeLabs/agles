'''
--USERS--

# will return an error if email is already in use
x - user_id : int = create(email, passwordHash, information)

# throws error if no user found
x - userId : int = getUserId(email, passwordHash)
x - user : dict = getUser(email, passwordHash)
x - user : dict = getUserFromId(userId)


--REPOSITORIES--

# throws error if invalid user
# can return empty list if no repositories for user
x - repositoryIds[] : int = getWritableRepoIds(userId)
x - repositories[] : dict = getWritableRepos(userId)
x - repository : dict = getRepoFromId(userId, repositoryId)


--BUILDS--

# returns build of buildId
x - build = getFromId(userId, buildId)

# returns builds [startIndex, endIndex) of type
#   if endIndexExclusive?, goes until end
x - builds[] = getRange(userId, repositoryId, type, startIndexInclusive, endIndexExclusive)


--BUILD OUTPUTS--

# returns array of lines (might be smarter way of doing this...)
buildCompileLines[] : dict = getCompilationOutput(userId, buildId)
buildTestLines[] : dict = getTestOutput(userId, buildId)
<more to be added>
'''
import database
import database.schema
import binascii

from hashlib import sha512

from nose.tools import *

import model_server

from bunnyrpc.exceptions import RPCRequestError
from database.engine import ConnectionFactory
from settings.mail import MailSettings
from settings.deployment import DeploymentSettings
from settings.store import StoreSettings
from util.test import BaseIntegrationTest
from util.test.mixins import ModelServerTestMixin, RabbitMixin


class ModelServerFrontEndApiTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):

	EMAIL = 'jchu@lt3.com'
	REPO_NAME = 'TestRepository'
	REPO_URI = REPO_NAME + '.git'

	@classmethod
	def setup_class(cls):
		super(ModelServerFrontEndApiTest, cls).setup_class()
		cls._purge_queues()

	def setUp(self):
		super(ModelServerFrontEndApiTest, self).setUp()
		self._start_model_server()
		self._create_user()
		self._create_repostore()
		self._create_repo()

	def tearDown(self):
		super(ModelServerFrontEndApiTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

###################
#	USERS
###################

	def _create_user(self):
		self.password_hash = binascii.b2a_base64(sha512().digest())[0:-1]
		self.user_info = {'email': self.EMAIL, 'first_name': 'bob', 'last_name': 'barker',
			'password_hash': self.password_hash, 'salt': 'Sodium Chloride.', 'admin': True}
		with model_server.rpc_connect("users", "create") as conn:
			self.user_id = conn.create_user(self.user_info['email'], self.user_info['first_name'],
				self.user_info['last_name'], self.user_info['password_hash'], self.user_info['salt'],
				self.user_info['admin'])

	def _assert_dict_subset(self, expected, actual):
		for key in expected.iterkeys():
			assert_equal(expected[key], actual[key])

	def test_get_user_id(self):
		with model_server.rpc_connect("users", "read") as conn:
			user_id = conn.get_user_id(self.EMAIL)
		assert_equal(self.user_id, user_id)

	def test_get_user(self):
		with model_server.rpc_connect("users", "read") as conn:
			user = conn.get_user(self.EMAIL)
		self._assert_dict_subset(self.user_info, user)

	def test_get_user_from_id(self):
		with model_server.rpc_connect("users", "read") as conn:
			user = conn.get_user_from_id(self.user_id)
		self._assert_dict_subset(self.user_info, user)

	def test_basic_set_admin(self):
		with model_server.rpc_connect("users", "create") as conn:
			created_user_id = conn.create_user('email', 'user_first', 'user_last', self.password_hash, 'Sodium Chloride.', False)
		with model_server.rpc_connect("users", "update") as conn:
			conn.set_admin(self.user_id, created_user_id, True)
			conn.set_admin(created_user_id, self.user_id, False)
			assert_raises(RPCRequestError, conn.set_admin, self.user_id, created_user_id, True)

#####################
#	REPOS
#####################

# TODO: FIX ALL OF THIS BELOW. THIS IS ALL HAX

	def _create_repostore(self):
		repostore = database.schema.repostore
		repostore_ins = repostore.insert().values(ip_address="127.0.0.1", repositories_path="/tmp")

		with ConnectionFactory.get_sql_connection() as conn:
			result = conn.execute(repostore_ins)
			self.repostore_id = result.inserted_primary_key[0]

	def _create_repo(self):
		with model_server.rpc_connect("repos", "create") as conn:
			self.repo_id = conn._create_repo_in_db(
				self.user_id,
				self.REPO_NAME,
				self.REPO_URI,
				self.repostore_id,
				"forwardurl",
				0,
				'git')

	def test_get_repositories(self):
		with model_server.rpc_connect("repos", "read") as conn:
			writable_repos = conn.get_repositories(self.user_id)
		repo = list(writable_repos).pop()
		assert_equal(self.repo_id, repo["id"])
		assert_equal(self.REPO_NAME, repo["name"])
		assert_equal(self.repostore_id, repo["repostore_id"])

	def test_get_repo_from_id(self):
		with model_server.rpc_connect("repos", "read") as conn:
			repo = conn.get_repo_from_id(self.user_id, self.repo_id)
		assert_equal(self.repo_id, repo["id"])
		assert_equal(self.REPO_NAME, repo["name"])
		assert_equal(self.repostore_id, repo["repostore_id"])

	def test_get_deleted_repo(self):
		with model_server.rpc_connect("repos", "delete") as conn:
			conn.delete_repo(self.user_id, self.repo_id)
		with model_server.rpc_connect("repos", "read") as conn:
			repos = conn.get_repositories(self.user_id)
		assert_true(len(repos) == 0)

	def test_create_duplicate_repo(self):
		try:
			self._create_repo()
		except RPCRequestError as e:
			assert_true('RepositoryAlreadyExistsError' in str(e))
		except:
			assert_true(False, 'Should raise a RepositoryAlreadyExistsError')
		else:
			assert_true(False, 'Should raise a RepositoryAlreadyExistsError')

#####################
#	SYSTEM SETTINGS
#####################

	def test_domain_name(self):
		domain_name = "Old_Domain"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_website_domain_name(self.user_id, domain_name)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals(domain_name, conn.get_website_domain_name(self.user_id))

		domain_name = "this.IS a N3W domain N@ME"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_website_domain_name(self.user_id, domain_name)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals(domain_name, conn.get_website_domain_name(self.user_id))

	def test_s3_bucket_name(self):
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "aws")

		bucket_name = 'ImABukkit'
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_s3_bucket_name(self.user_id, bucket_name)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals(bucket_name, conn.get_s3_bucket_name(self.user_id))

		bucket_name = 'Nooo-they-be-stealin-mah-bukkit'
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_s3_bucket_name(self.user_id, bucket_name)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals(bucket_name, conn.get_s3_bucket_name(self.user_id))

		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "hpcloud")
			assert_raises(AssertionError, conn.set_s3_bucket_name, self.user_id, bucket_name)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_raises(AssertionError, conn.get_s3_bucket_name, self.user_id)

	def test_aws_keys(self):
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "aws")

		access_key = "access KEY"
		secret_key = "SUPER_secret"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_aws_keys(self.user_id, access_key, secret_key, False)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals({"access_key": access_key, "secret_key": secret_key}, conn.get_aws_keys(self.user_id))

		access_key = "abc123XYZ"
		secret_key = "#!/\\(0xf ?'"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_aws_keys(self.user_id, access_key, secret_key, False)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals({"access_key": access_key, "secret_key": secret_key}, conn.get_aws_keys(self.user_id))

		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "hpcloud")
			assert_raises(AssertionError, conn.set_aws_keys, self.user_id, access_key, secret_key, False)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_raises(AssertionError, conn.get_aws_keys, self.user_id)

	def test_hpcloud_keys(self):
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "hpcloud")

		access_key = "access KEY"
		secret_key = "SUPER_secret"
		tenant_name = "a tenant"
		region = "region-1"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_hpcloud_keys(self.user_id, access_key, secret_key, tenant_name, region, False)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals({"access_key": access_key, "secret_key": secret_key, "tenant_name": tenant_name, "region": region}, conn.get_hpcloud_keys(self.user_id))

		access_key = "abc123XYZ"
		secret_key = "#!/\\(0xf ?'"
		tenant_name = "a different tenant"
		region = "region-2 west"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_hpcloud_keys(self.user_id, access_key, secret_key, tenant_name, region, False)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals({"access_key": access_key, "secret_key": secret_key, "tenant_name": tenant_name, "region": region}, conn.get_hpcloud_keys(self.user_id))

		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "aws")
			assert_raises(AssertionError, conn.set_hpcloud_keys, self.user_id, access_key, secret_key, tenant_name, region, False)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_raises(AssertionError, conn.get_hpcloud_keys, self.user_id)

	def test_aws_allowed_instance_sizes(self):
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "aws")

		with model_server.rpc_connect("system_settings", "read") as conn:
			allowed_instance_sizes = conn.get_aws_allowed_instance_sizes(self.user_id)
		assert_is_instance(allowed_instance_sizes, list)
		assert_less(0, len(allowed_instance_sizes))

		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "hpcloud")
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_raises(AssertionError, conn.get_aws_allowed_instance_sizes, self.user_id)

	def test_aws_instance_settings(self):
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "aws")

		security_group_name = "a security group"
		subnet_id = "a subnet"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_aws_instance_settings(self.user_id, security_group_name, subnet_id)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals({"security_group_id": security_group_name, "subnet_id": subnet_id},
				conn.get_aws_instance_settings(self.user_id))

		security_group_name = "a different security group"
		subnet_id = "a different subnet"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_aws_instance_settings(self.user_id, security_group_name, subnet_id)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals({"security_group_id": security_group_name, "subnet_id": subnet_id},
				conn.get_aws_instance_settings(self.user_id))

		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "hpcloud")
			assert_raises(AssertionError, conn.set_aws_instance_settings, self.user_id, security_group_name, subnet_id)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_raises(AssertionError, conn.get_aws_instance_settings, self.user_id)

	def test_hpcloud_instance_settings(self):
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "hpcloud")

		security_group_name = "a security group"
		instance_size = "m1.medium"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_hpcloud_instance_settings(self.user_id, instance_size, security_group_name)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals({"instance_size": instance_size, "security_group_name": security_group_name},
				conn.get_hpcloud_instance_settings(self.user_id))

		security_group_name = "a different security group"
		instance_size = "m2.2xlarge"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_hpcloud_instance_settings(self.user_id, instance_size, security_group_name)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals({"instance_size": instance_size, "security_group_name": security_group_name},
				conn.get_hpcloud_instance_settings(self.user_id))

		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_cloud_provider(self.user_id, "aws")
			assert_raises(AssertionError, conn.set_hpcloud_instance_settings, self.user_id, instance_size, security_group_name)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_raises(AssertionError, conn.get_hpcloud_instance_settings, self.user_id)

	def test_verifier_pool_parameters(self):
		min_ready = 42
		max_running = 69
		ami_id = "i-123456"
		vm_username = "ubuntu"
		root_drive_size = 42
		instance_type = "m1.medium"
		user_data = "#!/bin/bash\necho hi"
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_verifier_pool_parameters(self.user_id, 0, min_ready, max_running,
				instance_type, ami_id, vm_username, root_drive_size, user_data)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals([{"id": 0, "name": "default", "min_ready": min_ready, "max_running": max_running,
				"instance_type": instance_type, "ami_id": ami_id, "vm_username": vm_username,
				"root_drive_size": root_drive_size, "user_data": user_data}],
				conn.get_verifier_pool_parameters(self.user_id))

		min_ready = 1337
		max_running = 9001
		ami_id = "i-abcdef"
		vm_username = "bbland"
		root_drive_size = 1337
		instance_type = "m2.2xlarge"
		user_data = ""
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.set_verifier_pool_parameters(self.user_id, 0, min_ready, max_running,
				instance_type, ami_id, vm_username, root_drive_size, user_data)
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_equals([{"id": 0, "name": "default", "min_ready": min_ready, "max_running": max_running,
				"instance_type": instance_type, "ami_id": ami_id, "vm_username": vm_username,
				"root_drive_size": root_drive_size, "user_data": user_data}],
				conn.get_verifier_pool_parameters(self.user_id))

	def test_deployment_settings(self):
		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_false(conn.is_deployment_initialized())
		assert_is_none(DeploymentSettings.server_id)
		assert_is_none(StoreSettings.ssh_private_key)
		assert_is_none(StoreSettings.ssh_public_key)

		MailSettings.test_mode = False

		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.initialize_deployment(self.user_id, True)

		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_true(conn.is_deployment_initialized())
			assert_is_not_none(conn.get_admin_api_key(self.user_id))
		assert_true(MailSettings.test_mode)
		assert_is_not_none(DeploymentSettings.admin_api_key)
		assert_is_not_none(DeploymentSettings.server_id)
		assert_is_not_none(StoreSettings.ssh_private_key)
		assert_is_not_none(StoreSettings.ssh_public_key)

	def test_recreate_admin_api_key(self):
		with model_server.rpc_connect("system_settings", "update") as conn:
			conn.initialize_deployment(self.user_id, True)

		with model_server.rpc_connect("system_settings", "read") as conn:
			assert_true(conn.is_deployment_initialized())
			assert_is_not_none(conn.get_admin_api_key(self.user_id))

		with model_server.rpc_connect("system_settings", "update") as conn:
			new_api_key = conn.regenerate_api_key(self.user_id)

		assert_equals(new_api_key, DeploymentSettings.admin_api_key)
