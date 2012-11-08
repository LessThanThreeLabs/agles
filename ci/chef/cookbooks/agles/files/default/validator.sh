#!/bin/bash
for command in "$@"
	do echo \\$ $command
	$command
	r=$?
	if [ $r -ne 0 ]
		then echo "$command failed with return code: $r"
		exit $r
	fi
done
