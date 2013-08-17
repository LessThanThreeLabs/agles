#!/usr/bin/env python
"""Model server must be up to run this file since it depends on DatabaseBackedSettings"""

import argparse
from util.test import fake_data_generator


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("-s", "--seed",
		help="Random seed to be used")
	parser.set_defaults(seed=None)
	args = parser.parse_args()

	generator = fake_data_generator.SchemaDataGenerator(args.seed)
	generator.generate()


if __name__ == "__main__":
	main()
