#!/bin/bash

PWD=$(dirname ${BASH_SOURCE})

. $PWD/../util.sh

desc "Creating a Key Vault"
run "az account list-locations | jq -r '.[].name'"

KV_RG="acs-engine-demo-kv"
KV_LOC="westeurope"
KV_NAME="demo-kv"

run "az group create --name=${KV_RG} --location='${KV_LOC}'"

run "az keyvault create --name '$KV_NAME' --resource-group '$KV_RG' --location '$KV_LOC' --enabled-for-template-deployment true"
