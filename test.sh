#/bin/bash
((z=RANDOM%4))

if [ $z -le 2 ]; then
	exit 0
else
	exit 1
fi
