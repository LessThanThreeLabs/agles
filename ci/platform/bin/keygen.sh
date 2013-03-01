#!/usr/bin/env bash
if [ ! -d ~/.ssh ]; then
	# Create ssh directory if nonexistent
	mkdir ~/.ssh
fi
if [ ! -f ~/.ssh/id_rsa ]; then
	# Generate a new RSA ssh key if nonexistent
	ssh-keygen -t rsa -f ~/.ssh/id_rsa -N '' -q
fi
echo "Copy the public key below:"
# Print out the ssh public key
cat ~/.ssh/id_rsa.pub
