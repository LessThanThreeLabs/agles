#!/usr/bin/env python
from settings.deployment import DeploymentSettings


def main():
	print DeploymentSettings.active


if __name__ == '__main__':
	main()
