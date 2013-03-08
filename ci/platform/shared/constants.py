class VerificationUser(object):
	id = 1


class BuildStatus(object):
	QUEUED = 'queued'
	RUNNING = 'running'
	PASSED = 'passed'
	FAILED = 'failed'


class MergeStatus(object):
	PASSED = 'passed'
	FAILED = 'failed'
