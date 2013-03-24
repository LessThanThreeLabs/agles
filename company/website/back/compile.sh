#!/bin/bash 
cd $(dirname $0)
iced --compile --lint --output js/ src/
