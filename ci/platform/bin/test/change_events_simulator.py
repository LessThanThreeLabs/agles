#!/usr/bin/python
import random
import string
import sys
import time

from kombu.connection import Connection
from model_server.events_broker import EventsBroker
from settings.rabbit import RabbitSettings
from shared.constants import BuildStatus


class Globals(object):
	console_id = 1


def main():
	if len(sys.argv) < 2:
		print "Must provide a repository id and optionally a change number"
		sys.exit(1)
	repo_id = int(sys.argv[1])
	if len(sys.argv) == 3:
		change_id = int(sys.argv[2])
	else:
		change_id = random.randint(9001, 9999)
	mock_change(repo_id, change_id)


def mock_change(repo_id, change_id):
	publish_event("repos", repo_id, "change added", change_id=change_id, change_number=change_id,
		change_status="queued", commit_id=change_id, merge_target="master")
	time.sleep(random.uniform(0, 2))
	publish_event("repos", repo_id, "change started", change_id=change_id, status=BuildStatus.RUNNING, start_time=int(time.time()))
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
	publish_event("repos", repo_id, "change finished", change_id=change_id, status=BuildStatus.PASSED, end_time=int(time.time()))


def mock_stage(change_id, step_name, num_substeps):
	for step_number in range(num_substeps):
		publish_event("changes", change_id, "new build console", id=Globals.console_id, type=step_name,
			subtype="%s_%d" % (step_name, step_number), return_code=None)
		time.sleep(random.uniform(0, 1))
		for line_number in range(random.randint(10, 300)):
			publish_event("build_consoles", Globals.console_id, "new output", line_num=line_number, line=random_line())
			time.sleep(random.uniform(0, 0.1))
		publish_event("build_consoles", Globals.console_id, "return code added", return_code=0)
		Globals.console_id += 1


def random_line():
	return ''.join(random.choice(string.ascii_uppercase + string.digits) for x in range(random.randint(1, 100)))


def publish_event(_resource, _id, _event_type, **contents):
	with Connection(RabbitSettings.kombu_connection_info) as connection:
		broker = EventsBroker(connection)
		broker.publish(_resource, _id, _event_type, **contents)
		print contents


if __name__ == '__main__':
	main()
