class VerificationUser(object):
	id = 1


class BuildStatus(object):
	QUEUED = "queued"
	RUNNING = "running"
	COMPLETE = "complete"
	FAILED = "failed"
	MERGE_FAILURE = "merge failure"
