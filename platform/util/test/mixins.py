""" mixins.py - contains test mixins

This module contains all mixins meant to be used for unit testing.

Mixins are NOT meant to be instantiated and should never be instantiated.
Instantiating a mixin violates the mixin paradigm and will have unintended side
consequences/side effects.
"""
import os

from model_server import ModelServer


class BaseTestMixin(object):
	"""A base class for testing mixins."""
	pass


class ModelServerTestMixin(BaseTestMixin):
	"""Mixin for integration tests that require a running model server"""

	def _start_model_server(self):
		self.model_server = ModelServer()
		self.model_server.start()

	def _stop_model_server(self):
		self.model_server.stop()


class RepoStoreTestMixin(BaseTestMixin):
	def _modify_commit_push(self, repo, filename, contents, parent_commits=None,
	                        refspec="HEAD:master"):
		with open(os.path.join(repo.working_dir, filename), "w") as f:
			f.write(contents)
		repo.index.add([filename])
		commit = repo.index.commit("", parent_commits=parent_commits)
		repo.remotes.origin.push(refspec=refspec)
		return commit
