#!/bin/bash
_private_key=$(readlink -e $GIT_DIR).id_rsa
ssh -i $_private_key $*
