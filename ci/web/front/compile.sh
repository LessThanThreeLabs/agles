#!/bin/bash
iced --compile --lint --output js/src/ src/ &
icedPid=$!
./compileLessTree.sh
lessRc=$?
wait $icedPid
icedRc=$?
if [ $lessRc -ne "0" -a $icedRc -ne "0" ]; then
	printf "\x1b[31;1mFailed to compile less and coffeescript\x1b[0m\n"
	exit $lessRc
elif [ $lessRc -ne "0" ]; then
	printf "\x1b[31;1mFailed to compile less\x1b[0m\n"
	exit $lessRc
elif [ $icedRc -ne "0" ]; then
	printf "\x1b[31;1mFailed to compile coffeescript\x1b[0m\n"
	exit $icedRc
else
	printf "\x1b[32;1mSuccessfully compiled\x1b[0m\n"
fi
