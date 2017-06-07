#!/bin/bash

PWD=$(dirname ${BASH_SOURCE})

set -e
SERVICE_PRINCIPAL_ID=$(cat service-principal-id.txt)
set +e

. $PWD/../util.sh

desc "Deleting Service Principal"
run "az ad sp delete --id=${SERVICE_PRINCIPAL_ID}"
