# repo_manager.py -- Implements a manager for git repositories using dulwich

"""Git repository manager for server side git repositories.

Repository managment is done using a modified version of dulwich, 
a git implementation written in python.

* For more information on the modified dulwich, see the submodule.
"""

import os
import shutil

from os import sep
from dulwich.repo import Repo

class FileSystemRepoManager(object):
	"""Management class for server side git repositories"""

	DIR_LEVELS = 3
	
	def __init__(self):
		pass

	def create(self, repo_hash, repo_name):
		"""Creates a new server side repository.
		We create bare repositories because they are server side.

		:param repo_hash: A unique hash assigned to each repository that determines which directory
						  the repository is stored under.
		:param repo_name: The name of the new repository.
		:return: The newly created repository.
		"""

		repo_path = self._resolve_path(repo_hash, repo_name)
		if not os.path.exists(repo_path):
			os.makedirs(repo_path)
		else:
			raise RepositoryAlreadyExistsException(repo_hash, repo_path)
		repo = Repo.init_bare(repo_path)
		return repo

	def delete(self, repo_hash, repo_name):
		"""Deletes a server side repository. This cannot be undone.

		:param repo_hash: A unique hash assigned to each repository that determines which directory
						  the repository is stored under.
		:param repo_name: The name of the repository to be deleted.
		"""
		repo_path = self._resolve_path(repo_hash, repo_name)
		shutil.rmtree(repo_path)

	def rename(self, old_name, new_name):
		"""Renames a repository.

		:param repo_hash: A unique hash assigned to each repository that determines which directory
						  the repository is stored under.
		:param old_name: The old repository name.
		:param new_name: The new repository name.
		:return: The renamed repository.
		"""

		old_repo_path = self._resolve_path(repo_hash, old_name)
		new_repo_path = self._resolve_path(repo_hash, new_name)
		if not os.path.exists(new_repo_path):
			shutil.move(old_repo_path, new_repo_path)
		else:
			raise RepositoryAlreadyExistsException(repo_hash, new_repo_path) 
		return Repo(new_repo_path)

	def _resolve_path(self, repo_hash, repo_name):
		repo_path = sep.join([self._directory_treeify(repo_hash, self.DIR_LEVELS), repo_name])
		return os.path.realpath(repo_path)

	def _directory_treeify(self, repo_hash, dir_levels):
		"""Takes a hash and separates it into directories (e.g. a23fe89 => a/2/3fe89)

		:param repo_hash: The hash we are treeifying.
		:param dir_levels: The number of directory levels to create from repo_hash.
		:return: A string representing repo_hash with file separators up to dir_levels levels.
		"""
		return sep.join(repo_hash[:dir_levels]) + repo_hash[dir_levels:]


class RepositoryManagementException(Exception):
	"""Base class for exception relating to repository management."""

	def __init__(self, msg=''):
		Exception.__init__(self, msg)

class RepositoryAlreadyExistsException(RepositoryManagementException):
	"""Indicates an exception occured due to a repository already existing."""

	def __init__(self, repo_hash, existing_repo_path):
		RepositoryManagementException.__init__(
			self, 
			'Repository with hash %s already exists at path %s' % (repo_hash, existing_repo_path))
