VERSION = '0.1.6'

KOALITY_EXPORT_PATH = '/koality/export'


class VerificationUser(object):
	id = 1


class BuildStatus(object):
	QUEUED = 'queued'
	RUNNING = 'running'
	PASSED = 'passed'
	FAILED = 'failed'
	SKIPPED = 'skipped'


class MergeStatus(object):
	PASSED = 'passed'
	FAILED = 'failed'
