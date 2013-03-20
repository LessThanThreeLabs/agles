#!/bin/bash
back/compile.sh
front/compile.sh

karma start front/test/unit/karma.conf.js --browsers PhantomJS --single-run
