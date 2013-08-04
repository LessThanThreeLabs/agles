#!/usr/bin/env python
import argparse
import datetime
import sys
import util.log

from settings.verification_server import VerificationServerSettings
from virtual_machine.snapshotter import Snapshotter, SnapshotDaemon
from virtual_machine.ec2 import Ec2Vm
from virtual_machine.hpcloud import HpCloudVm
from virtual_machine.rackspace import RackspaceVm


def main():
	util.log.configure()

	parser = argparse.ArgumentParser()
	parser.add_argument('-d', '--daemon', action='store_true',
		help='Runs a daemon which snapshots daily')
	parser.add_argument('-c', '--cleanup', action='store_true',
		help='Clean up old snapshots')
	parser.add_argument('-p', '--provider',
		help='Selects the cloud provider. Supported options are "aws", "hpcloud", and "rackspace"')
	args = parser.parse_args()

	try:
		cloud_provider = args.provider
		if cloud_provider is None:
			cloud_provider = VerificationServerSettings.cloud_provider
			if cloud_provider is None:
				print 'Cloud provider not specified and not in stored settings; exiting'
				sys.exit(1)
			else:
				print 'Cloud provider not specified; defaulting to the stored settings value (%s)' % cloud_provider

		snapshotter = Snapshotter({
			'aws': Ec2Vm,
			'hpcloud': HpCloudVm,
			'rackspace': RackspaceVm
		}[cloud_provider])
	except:
		print 'Must supply either "aws", "hpcloud", or "rackspace" as a cloud provider'
		parser.print_usage()
		sys.exit(1)

	if args.daemon and args.cleanup:
		raise Exception('Must select only one of (--daemon, --cleanup)')
	elif args.daemon:
		run_snapshot_daemon(snapshotter)
	elif args.cleanup:
		remove_stale_snapshots(snapshotter)
	else:
		snapshot(snapshotter)


def snapshot(snapshotter):
	snapshotter.snapshot()


def run_snapshot_daemon(snapshotter):
	next_snapshot = _next_3am()
	snapshot_period = 60 * 60 * 24  # DAILY
	snapshot_daemon = SnapshotDaemon(snapshotter, next_snapshot, snapshot_period)
	snapshot_daemon.run()


def remove_stale_snapshots(snapshotter):
	snapshotter.remove_stale_snapshots()


def _next_3am():
	now = datetime.datetime.now()
	then = datetime.datetime(now.year, now.month, now.day, 3)
	if now.hour >= 3:
		then += datetime.timedelta(days=1)
	return then


if __name__ == '__main__':
	main()
