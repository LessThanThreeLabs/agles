#!/bin/bash
if [ "$(which phantomjs)" == "" ]; then
	cd /usr/local/share/
	wget http://phantomjs.googlecode.com/files/phantomjs-1.8.2-linux-x86_64.tar.bz2
	tar xjf phantomjs-1.8.2-linux-x86_64.tar.bz2
	ln -s /usr/local/share/phantomjs-1.8.2-linux-x86_64 /usr/local/share/phantomjs
	ln -s /usr/local/share/phantomjs/bin/phantomjs /usr/local/bin/phantomjs
fi
