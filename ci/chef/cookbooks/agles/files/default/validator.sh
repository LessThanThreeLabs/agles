#!/bin/bash
command=$*
echo -e \$ $command
timeout 120 bash -c "`echo -e $command`"
r=$?
if [ $r -eq 124 ]
	then echo "$command timed out after 120 seconds"
	exit $r
elif [ $r -ne 0 ]
	then echo "$command failed with return code: $r"
	exit $r
fi
