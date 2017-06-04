#!/bin/bash

PWD=$(dirname ${BASH_SOURCE})

. $PWD/../util.sh

desc "Installing Azure CLI"
run "curl -L https://aka.ms/InstallAzureCli | bash"
