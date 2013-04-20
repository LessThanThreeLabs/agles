#!/bin/bash
cd $(dirname $0)
rm -rf js/src
iced --compile --lint --output js/src/ src/ &
icedPidMain=$!

rm -rf test/js
iced --compile --lint --output test/js/ test/src/ &
icedPidTest=$!

./compileLessTree.sh
lessRc=$?

wait $icedPidMain
icedRcMain=$?

wait $icedPidTest
icedRcTest=$?

if [ $lessRc -ne 0 ] && [ $icedRcMain -ne 0 ] && [ $icedRcTest -ne 0 ]; then
	printf "\x1b[31;1mFailed to compile less and coffeescript\x1b[39;22m\n"
	exit $lessRc
elif [ $lessRc -ne 0 ]; then
	printf "\x1b[31;1mFailed to compile less\x1b[39;22m\n"
	exit $lessRc
elif [ $icedRcMain -ne 0 ] || [ $icedRcTest -ne 0 ]; then
	printf "\x1b[31;1mFailed to compile coffeescript\x1b[39;22m\n"
	let 'rc = $icedRcMain | $icedRcTest'
	exit rc
else
	printf "\x1b[35;1mSuccessfully compiled\x1b[39;22m\n"
fi
