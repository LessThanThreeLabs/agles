#!/bin/bash
back/compile.sh
front/compile.sh

karma start front/test/e2e/karma.conf.js --browsers PhantomJS --single-run
