#!/bin/bash

PWD=$(dirname ${BASH_SOURCE})

set -e
source $PWD/../settings.env
[[ ! -z "${SUBSCRIPTION_ID:-}" ]] || (echo "Must specify SUBSCRIPTION_ID" && exit -1)
set +e

. $PWD/../util.sh

desc "Initialize Azure Environment"
run "az login"
run "az account set --subscription=${SUBSCRIPTION_ID}"
