from setuptools import setup, find_packages

setup(
	name="koality",
	version="0.1",
	description="Production code for koality",
	packages=find_packages(exclude=[
		"bin",
		"tests",
	]),
)
