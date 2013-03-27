#!/usr/bin/env python
import argparse
import os
import shutil


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("version", metavar='v', type=str, help="The version number of this upgrade")
	parser.add_argument("directory", metavar='dir', type=str, help="The root directory of the code we are packaging")
	args = parser.parse_args()

	version_dir = "/tmp/%s" % args.version

	shutil.rmtree(version_dir, ignore_errors=True)
	os.makedirs(version_dir)
	shutil.copytree("%s/ci" % args.directory, "%s/ci" % version_dir)
	shutil.copy('%s/ci/platform/upgrade/upgrade_script' % version_dir, version_dir)
	shutil.copy('%s/ci/platform/upgrade/revert_script' % version_dir, version_dir)
	shutil.make_archive(args.version, format="gztar", base_dir=args.version, root_dir="/tmp")

if __name__ == "__main__":
	main()
