import os

DEFAULT_CHARS_PER_LEVEL = 2
DIR_LEVELS = 3


def path_sanitize_email(email):
	return email.replace("@", "AT").replace(".", "DOT")


def to_clone_path(email, repo_name):
	sanitized_email = path_sanitize_email(email)
	return "%s/%s" % (sanitized_email, repo_name)


def to_path(pathseed, name, dir_levels=DIR_LEVELS):
	return os.path.join(directory_treeify(pathseed, dir_levels), name)


def directory_treeify(pathseed, dir_levels=DIR_LEVELS):
	"""Takes a pathseed and separates it into directories (e.g. 1 => 00/00/01)

	:param pathseed: The thing we take and treeify.
	:param dir_levels: The number of directory levels to create from pathseed.
	:return: A string representing pathseed with file separators up to dir_levels levels.
	"""
	assert dir_levels > 0
	required_len = dir_levels * DEFAULT_CHARS_PER_LEVEL
	padded_id = str(pathseed).zfill(required_len)

	pivot = dir_levels * DEFAULT_CHARS_PER_LEVEL
	chunked_hash = map(''.join, zip(*[iter(padded_id[:pivot])] * DEFAULT_CHARS_PER_LEVEL))
	return os.path.join(*chunked_hash) + padded_id[pivot:]


def hidden_ref(commit_id):
	""" Converts a commit id to a hidden ref that the commit was stored in

	:param commit_id: The commit id stored in the hidden ref
	:return: The hidden ref that the commit is stored in
	"""
	return 'refs/pending/%s' % commit_id


def get_repo_id(abspath):
	# We start 2 from the back of the list because of ['repo_name', '.git']
	repo_id_path_end_index = -1
	repo_id_path_start_index = repo_id_path_end_index - DIR_LEVELS
	repo_id_string = ''.join(abspath.split('/')[repo_id_path_start_index:repo_id_path_end_index])
	return int(repo_id_string)
