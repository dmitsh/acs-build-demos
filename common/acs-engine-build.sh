#!/bin/bash

PWD=$(dirname ${BASH_SOURCE})

. $PWD/../util.sh

desc "Download acs-engine"
export GOPATH=$(realpath $PWD/../gopath)
show "mkdir -p \$GOPATH/src/github.com/Azure/"
mkdir -p $GOPATH/src/github.com/Azure/

show "cd \$GOPATH/src/github.com/Azure/"
cd $GOPATH/src/github.com/Azure/

run "git clone https://github.com/Azure/acs-engine.git"

desc "Build acs-engine"
run "cd acs-engine; make build"
cp acs-engine/acs-engine $GOPATH/bin/
