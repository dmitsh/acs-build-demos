#!/bin/bash

PWD=$(dirname ${BASH_SOURCE})

set -e
source $PWD/../settings.env
[[ ! -z "${SERVICE_PRINCIPAL_ID:-}" ]] || (echo "Must specify SERVICE_PRINCIPAL_ID" && exit -1)
set +e

. $PWD/../util.sh

desc "Deleting Service Principal"
run "az ad sp delete --id=${SERVICE_PRINCIPAL_ID}"
