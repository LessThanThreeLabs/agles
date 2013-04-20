#!/bin/bash
cd $(dirname $0)
rm -rf js
iced --compile --lint --output js/ src/
