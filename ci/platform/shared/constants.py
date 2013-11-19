VERSION = '0.7.4'

MAX_SPECIAL_USER_ID = 999

class VerificationUser(object):
	id = 3


class BuildStatus(object):
	QUEUED = 'queued'
	RUNNING = 'running'
	PASSED = 'passed'
	FAILED = 'failed'
	SKIPPED = 'skipped'


class MergeStatus(object):
	PASSED = 'passed'
	FAILED = 'failed'
