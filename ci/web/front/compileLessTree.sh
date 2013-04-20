#!/bin/bash
rm -rf css/src
declare -a pids=()
declare -a lessfiles=()
while read filename; do
	(	cssname=$(basename $filename .less).css
		outdir=$(echo $(dirname $filename) | sed s:/src/:/css/src/: | sed s:^src/:css/src/: | sed s:^src$:css/src:)
		if [ ! -d $outdir ]; then
			mkdir -p $outdir
		fi
		outfilename=$outdir/$cssname
		lessc $filename $outfilename ) &
	pid=$!
	pids+=( "$pid" )
	lessfiles+=( "$filename" )
done < <(find src -name "*.less")
failures=0
for (( i=0; i<$(( ${#pids[*]} )); i++ )); do
	pid="${pids[i]}"
	lessfile="${lessfiles[i]}"
	wait $pid
	if [ $? -ne 0 ]; then
		let failures=$failures+1
		printf "\x1b[31mFailed to compile file $lessfile\x1b[39m\n"
	else
		printf "\x1b[35mCompiled $lessfile successfully\x1b[39m\n"
	fi
done
if [ $failures -ne 0 ]; then
	printf "\x1b[31;1mFailed to compile $failures less files\x1b[39;22m\n"
	exit 1
fi
printf "\x1b[35;1mAll less files compiled successfully\x1b[39;22m\n"
