#!/bin/bash

PWD=$(dirname ${BASH_SOURCE})

set -e
source $PWD/../settings.env
[[ ! -z "${SERVICE_PRINCIPAL_ID:-}" ]] || (echo "Must specify SERVICE_PRINCIPAL_ID" && exit -1)
[[ ! -z "${SERVICE_PRINCIPAL_SECRET:-}" ]] || (echo "Must specify SERVICE_PRINCIPAL_SECRET" && exit 1)
set +e

. $PWD/../util.sh

show "RESOURCE_GROUP=acs-engine-demo1"
RESOURCE_GROUP=acs-engine-demo1
show "DEPLOYMENT_NAME=\${RESOURCE_GROUP}"
DEPLOYMENT_NAME=${RESOURCE_GROUP}
show "DNS_PREFIX=\${RESOURCE_GROUP}"
DNS_PREFIX=${RESOURCE_GROUP}
show "LOCATION=westus2"
LOCATION=eastus

desc "Create ssh key"
run "ssh-keygen -t rsa -f id_rsa_demo -N ''"

cp $PWD/kubernetes-api-model-prep.json kubernetes.json

desc "Complete api-model file"
run "cat kubernetes.json"

show "jq \".properties.masterProfile.dnsPrefix = \\\"\${DNS_PREFIX}\\\"\" kubernetes.json > tmp && mv tmp kubernetes.json"
jq ".properties.masterProfile.dnsPrefix = \"${DNS_PREFIX}\"" kubernetes.json > tmp && mv tmp kubernetes.json

show "jq \".properties.servicePrincipalProfile.servicePrincipalClientID = \\\"\${SERVICE_PRINCIPAL_ID}\\\"\" kubernetes.json > tmp && mv tmp kubernetes.json"
jq ".properties.servicePrincipalProfile.servicePrincipalClientID = \"${SERVICE_PRINCIPAL_ID}\"" kubernetes.json > tmp && mv tmp kubernetes.json

show "jq \".properties.servicePrincipalProfile.servicePrincipalClientSecret = \\\"\${SERVICE_PRINCIPAL_SECRET}\\\"\" kubernetes.json > tmp && mv tmp kubernetes.json"
jq ".properties.servicePrincipalProfile.servicePrincipalClientSecret = \"${SERVICE_PRINCIPAL_SECRET}\"" kubernetes.json > tmp && mv tmp kubernetes.json

show "jq \".properties.linuxProfile.ssh.publicKeys[0].keyData = \\\"\$(cat id_rsa_demo.pub)\\\"\" kubernetes.json > tmp && mv tmp kubernetes.json"
jq ".properties.linuxProfile.ssh.publicKeys[0].keyData = \"$(cat id_rsa_demo.pub)\"" kubernetes.json > tmp && mv tmp kubernetes.json

run "cat kubernetes.json"

desc "Create ARM deployment template and parameters file"
export GOPATH=$(realpath $PWD/../gopath)
run "$GOPATH/bin/acs-engine generate --api-model ./kubernetes.json"

desc "Create deployment"
run "az group create --name=${RESOURCE_GROUP} --location=${LOCATION}"

run "az group deployment create \
--name "${DEPLOYMENT_NAME}" \
--resource-group "${RESOURCE_GROUP}" \
--template-file ./_output/${DNS_PREFIX}/azuredeploy.json \
--parameters @./_output/${DNS_PREFIX}/azuredeploy.parameters.json"

show "export KUBECONFIG=\"./_output/${DNS_PREFIX}/kubeconfig/kubeconfig.${LOCATION}.json\""
export KUBECONFIG="./_output/${DNS_PREFIX}/kubeconfig/kubeconfig.${LOCATION}.json"
run "kubectl get nodes"
run "ssh -i id_rsa_demo -o 'ConnectTimeout 60' -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' azureuser@${DNS_PREFIX}.${LOCATION}.cloudapp.azure.com hostname"
