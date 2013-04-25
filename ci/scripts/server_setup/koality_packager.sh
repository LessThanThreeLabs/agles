#!/bin/bash

function package_python () {
	mkdir $python_path
	virtualenv $python_path/koality-env --no-site-packages # -p MODIFIED_PYTHON
	source $python_path/koality-env/bin/activate
	easy_install pip
	cp -r $platform_dir $python_path
	if [ "$(basename $platform_dir)" != "platform" ]; then
		mv $python_path/$(basename $platform_dir) $python_path/platform
	fi
	pushd $python_path/platform
	pip install -r requirements.txt
	python setup.py install
	popd
	python -OO -m compileall $python_path
	rm -rf $python_path/**/*.py
	echo "koality python packaged into $(pwd)/$virtualenv_name"
}

function package_node () {
	mkdir $node_path
	mkdir $node_path/nvm
	wget -P $node_path/nvm https://raw.github.com/creationix/nvm/master/nvm.sh
	source $node_path/nvm/nvm.sh
	nvm install $node_version
	cp -r $web_dir $node_path
	if [ "$(basename $web_dir)" != "web" ]; then
		mv $node_path/$(basename $web_dir) $node_path/web
	fi
	pushd $node_path/web/back
	npm install
	popd
	echo "koality node packaged into $(pwd)/$node_path"
}

function abspath () {
	pushd $(dirname $1) > /dev/null
	echo $(pwd)/$(basename $1)
	popd > /dev/null
}

function main () {
	koality_version=$1
	platform_dir=$2
	web_dir=$3

	if [ ! "$koality_version" ]; then
		echo "must provide a version"
		exit 1
	fi

	if [ ! -d "$platform_dir" ]; then
		echo "platform directory \"$platform_dir\" must exist"
		exit 1
	else
		platform_dir=$(abspath $platform_dir)
	fi

	if [ ! -d "$web_dir" ]; then
		echo "web directory \"$web_dir\" must exist"
		exit 1
	else
		web_dir=$(abspath $web_dir)
	fi

	mkdir koality-$koality_version
	pushd koality-$koality_version

	python_path=python
	node_path=node

	package_python
	package_node
	popd
}

main $*
