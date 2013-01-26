class VerificationUser(object):
	id = 1


class BuildStatus(object):
	QUEUED = 'queued'
	RUNNING = 'running'
	PASSED = 'passed'
	FAILED = 'failed'
	FAILED_TO_MERGE = 'failed to merge'
