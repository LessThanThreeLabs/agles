#!/bin/bash
cd $(dirname $0)
iced --compile --lint --output js/src/ src/ &
icedPid=$!
./compileLessTree.sh
lessRc=$?
wait $icedPid
icedRc=$?
if [ $lessRc -ne 0 ] && [ $icedRc -ne 0 ]; then
	printf "\x1b[31;1mFailed to compile less and coffeescript\x1b[39;22m\n"
	exit $lessRc
elif [ $lessRc -ne 0 ]; then
	printf "\x1b[31;1mFailed to compile less\x1b[39;22m\n"
	exit $lessRc
elif [ $icedRc -ne 0 ]; then
	printf "\x1b[31;1mFailed to compile coffeescript\x1b[39;22m\n"
	exit $icedRc
else
	printf "\x1b[35;1mSuccessfully compiled\x1b[39;22m\n"
fi
