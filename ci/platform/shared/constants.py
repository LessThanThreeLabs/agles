VERSION = '0.2.1'

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
