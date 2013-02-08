import random
import string
import sys
import time

from kombu.connection import Connection
from model_server.events_broker import EventsBroker
from settings.rabbit import RabbitSettings
from shared.constants import BuildStatus


console_id = 1


def main():
	if len(sys.argv) < 1:
		print "Must provide a repository id and optionally a change number"
	repo_id = sys.argv[0]
	change_id = sys.argv.get(1, random.randint(9001, 9999))
	mock_change(repo_id, change_id)


def mock_change(repo_id, change_id):
	publish_event("repos", repo_id, "change added", change_id=change_id, change_number=change_id,
		change_status="queued", commit_id=change_id, merge_target="master")
	time.sleep(random.uniform(0, 2))
	publish_event("changes", change_id, "change started", status=BuildStatus.RUNNING, start_time=int(time.time()))
	time.sleep(random.uniform(0, 2))
	publish_event("changes", change_id, "build added", build_id=change_id, commit_list=["ABCDEF123456"])
	time.sleep(random.uniform(0, 2))
	publish_event("builds", change_id, "build started", status=BuildStatus.RUNNING)
	time.sleep(random.uniform(0, 2))
	mock_stage(change_id, "setup", 2)
	mock_stage(change_id, "compile", 2)
	mock_stage(change_id, "test", 4)
	time.sleep(random.uniform(0, 2))
	publish_event("builds", change_id, "build finished", status=BuildStatus.PASSED)
	time.sleep(random.uniform(0, 2))
	publish_event("changes", change_id, "change finished", status=BuildStatus.PASSED, end_time=int(time.time()))


def mock_stage(change_id, step_name, num_substeps):
	for step_number in range(num_substeps):
		publish_event("changes", change_id, "new build console", id=console_id, type=step_name,
			subtype="%s_%d" % (step_name, step_number), return_code=None)
		time.sleep(random.uniform(0, 1))
		for line_number in range(random.randint(10, 300)):
			publish_event("build_consoles", console_id, "new_output", line_num=line_number, line=random_line())
			time.sleep(random.uniform(0, 0.2))
		publish_event("build_consoles", console_id, "return code added", return_code=0)


def random_line():
	''.join(random.choice(string.ascii_uppercase + string.digits) for x in range(random.randint(1, 100)))


def publish_event(self, _resource, _id, _event_type, **contents):
	with Connection(RabbitSettings.kombu_connection_info) as connection:
		broker = EventsBroker(connection)
		broker.publish(_resource, _id, _event_type, **contents)


if __name__ == '__main__':
	main()
