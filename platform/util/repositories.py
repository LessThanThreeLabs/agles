# repositories.py - a util class for interacting with repositories

import os
import os.path


def to_path(repo_hash, name, dir_levels):
	return os.path.join(directory_treeify(repo_hash, dir_levels), name)

def directory_treeify(repo_hash, dir_levels):
	"""Takes a hash and separates it into directories (e.g. a23fe89 => a/2/3fe89)

	:param repo_hash: The hash we are treeifying.
	:param dir_levels: The number of directory levels to create from repo_hash.
	:return: A string representing repo_hash with file separators up to dir_levels levels.
	"""
	return os.path.join(*repo_hash[:dir_levels]) + repo_hash[dir_levels:]

def hidden_ref(commit_id):
	""" Converts a commit id to a hidden ref that the commit was stored in

	:param commit_id: The commit id stored in the hidden ref
	:return: The hidden ref that the commit is stored in
	"""
	return os.sep.join(['refs/pending', str(commit_id)])
