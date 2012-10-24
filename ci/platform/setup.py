from setuptools import setup, find_packages

setup(
	name="agles",
	version="0.1",
	description="Production code for agles",
	packages=find_packages(exclude=[
		"bin",
		"aws_t",
		"tests",
	]),
)