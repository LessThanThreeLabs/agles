#!/bin/bash
command=$*
tmpfile=$(cd "$(dirname "$0")"; pwd)/$(basename "$0").tmp
echo -e \$ $command
echo -e $command > $tmpfile
chmod +x $tmpfile
source $tmpfile
r=$?
rm $tmpfile
if [ $r -ne 0 ]
	then echo "$command failed with return code: $r"
	exit $r
fi
