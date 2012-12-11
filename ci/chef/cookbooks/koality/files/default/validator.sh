#!/bin/bash
command=$*
echo -e \$ $command
$command
r=$?
if [ $r -ne 0 ]
	then echo "$command failed with return code: $r"
	exit $r
fi
