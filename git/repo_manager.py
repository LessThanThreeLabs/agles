# repo_manager.py -- Implements a manager for git repositories using dulwich

"""Git repository manager for server side git repositories.

Repository managment is done using a modified version of dulwich, 
a git implementation written in python.

* For more information on the modified dulwich, see the submodule.
"""

import os
import shutil

from dulwich.repo import Repo

class RepoManager(object):
	"""Management class for server side git repositories"""
	
	def __init__(self):
		pass

	def create(self, repo_name):
		"""Creates a new server side repository.
		We create bare repositories because they are server side.

		:param repo_name: The name of the new repository.
		:return: The newly created repository.
		"""

		# TODO: figure out where/how we are storing repositories
		if not os.path.exists(repo_name):
			os.mkdir(repo_name)
		else:
			raise RepositoryAlreadyExistsException(repo_name)
		repo = Repo.init_bare(repo_name)
		return repo

	def delete(self, repo_name):
		"""Deletes a server side repository. This cannot be undone.

		:param repo_name: The name of the repository to be deleted.
		"""

		shutil.rmtree(repo_name)

	def rename(self, old_name, new_name):
		"""Renames a repository.

		:param old_name: The old repository name.
		:param new_name: The new repository name.
		:return: The renamed repository.
		"""

		if not os.path.exists(new_name):
			shutil.move(old_name, new_name)
		else:
			raise RepositoryAlreadyExistsException(new_name) 
		return Repo(new_name)

class RepositoryManagementException(Exception):
	"""Base class for exception relating to repository management."""

	def __init__(self, msg=''):
		Exception.__init__(self, msg)

class RepositoryAlreadyExistsException(RepositoryManagementException):
	"""Indicates an exception occured due to a repository already existing."""

	def __init__(self, existing_repo):
		RepositoryManagementException.__init__(
			self, 
			'Repository %s already exists' % new_name)
