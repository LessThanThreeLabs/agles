# repositories.py - a util class for interacting with repositories

import os

DEFAULT_CHARS_PER_LEVEL = 2
DIR_LEVELS = 3


def to_path(hash, name, dir_levels=DIR_LEVELS):
	return os.path.join(directory_treeify(hash, dir_levels), name)


def directory_treeify(hash, dir_levels=DIR_LEVELS):
	"""Takes a hash and separates it into directories (e.g. a23fe89 => a/2/3fe89)

	:param hash: The hash we are treeifying.
	:param dir_levels: The number of directory levels to create from repo_hash.
	:return: A string representing repo_hash with file separators up to dir_levels levels.
	"""
	assert dir_levels > 0
	assert len(hash) > (dir_levels - 1) * DEFAULT_CHARS_PER_LEVEL

	pivot = dir_levels * DEFAULT_CHARS_PER_LEVEL
	chunked_hash = map(''.join, zip(*[iter(hash[:pivot])] * DEFAULT_CHARS_PER_LEVEL))
	return os.path.join(*chunked_hash) + hash[pivot:]


def hidden_ref(commit_id):
	""" Converts a commit id to a hidden ref that the commit was stored in

	:param commit_id: The commit id stored in the hidden ref
	:return: The hidden ref that the commit is stored in
	"""
	return os.sep.join(['refs/pending', str(commit_id)])


def get_repo_hash(abspath):
	# We start 2 from the back of the list because of ['repo_name', '.git']
	hash_path_end_index = -1
	hash_path_start_index = hash_path_end_index - DIR_LEVELS
	return ''.join(abspath.split('/')[hash_path_start_index:hash_path_end_index])
