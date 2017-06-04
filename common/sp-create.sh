#!/bin/bash

PWD=$(dirname ${BASH_SOURCE})

set -e
source $PWD/../settings.env
[[ ! -z "${SUBSCRIPTION_ID:-}" ]] || (echo "Must specify SUBSCRIPTION_ID" && exit -1)
set +e

. $PWD/../util.sh

KV_RG="acs-engine-demo-kv"
KV_NAME="demo-kv"
KV_SECRET_NAME="sp-pwd"

desc "Creating a Service Principal"

run "cat $(realpath $PWD/../settings.env)"

run "az ad sp create-for-rbac --role=Contributor --scopes=/subscriptions/${SUBSCRIPTION_ID} > tmp"

show "sed -i \"/^SERVICE_PRINCIPAL_ID=/c SERVICE_PRINCIPAL_ID=\$(jq -r 'getpath([\"appId\"])' tmp)\" settings.env"
sed -i "/^SERVICE_PRINCIPAL_ID=/c SERVICE_PRINCIPAL_ID=$(jq -r 'getpath(["appId"])' tmp)" $PWD/../settings.env

show "az keyvault secret set --name ${KV_SECRET_NAME} --vault-name ${KV_NAME} --value \$(jq -r 'getpath([\"password\"])' tmp) > /dev/null"
az keyvault secret set --name ${KV_SECRET_NAME} --vault-name ${KV_NAME} --value $(jq -r 'getpath(["password"])' tmp) > /dev/null

run "rm tmp"

show "sed -i \"/^SERVICE_PRINCIPAL_SECRET=/c SERVICE_PRINCIPAL_SECRET=/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${KV_RG}/providers/Microsoft.KeyVault/vaults/${KV_NAME}/secrets/${KV_SECRET_NAME}\" settings.env"
sed -i "/^SERVICE_PRINCIPAL_SECRET=/c SERVICE_PRINCIPAL_SECRET=/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${KV_RG}/providers/Microsoft.KeyVault/vaults/${KV_NAME}/secrets/${KV_SECRET_NAME}"  $PWD/../settings.env

run "cat $(realpath $PWD/../settings.env)"
