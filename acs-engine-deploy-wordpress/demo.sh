#!/bin/bash

PWD=$(dirname ${BASH_SOURCE})

set -e
source $PWD/../settings.env
[[ ! -z "${SERVICE_PRINCIPAL_ID:-}" ]] || (echo "Must specify SERVICE_PRINCIPAL_ID" && exit -1)
[[ ! -z "${SERVICE_PRINCIPAL_SECRET:-}" ]] || (echo "Must specify SERVICE_PRINCIPAL_SECRET" && exit 1)
set +e

. $PWD/../util.sh

cp $PWD/kubernetes-api-model-prep.json kubernetes.json

desc "Complete api-model file"
run "cat kubernetes.json"

desc "Choose DNS prefix"
DNS_PREFIX=acs-engine-demo2
show "DNS_PREFIX=${DNS_PREFIX}"

#desc "Create ssh key"
#run "ssh-keygen -t rsa -f id_rsa_demo -N ''"

#show "jq \".properties.masterProfile.dnsPrefix = \\\"\${DNS_PREFIX}\\\"\" kubernetes.json > tmp && mv tmp kubernetes.json"
jq ".properties.masterProfile.dnsPrefix = \"${DNS_PREFIX}\"" kubernetes.json > tmp && mv tmp kubernetes.json

#show "jq \".properties.servicePrincipalProfile.servicePrincipalClientID = \\\"\${SERVICE_PRINCIPAL_ID}\\\"\" kubernetes.json > tmp && mv tmp kubernetes.json"
jq ".properties.servicePrincipalProfile.servicePrincipalClientID = \"${SERVICE_PRINCIPAL_ID}\"" kubernetes.json > tmp && mv tmp kubernetes.json

#show "jq \".properties.servicePrincipalProfile.servicePrincipalClientSecret = \\\"\${SERVICE_PRINCIPAL_SECRET}\\\"\" kubernetes.json > tmp && mv tmp kubernetes.json"
jq ".properties.servicePrincipalProfile.servicePrincipalClientSecret = \"${SERVICE_PRINCIPAL_SECRET}\"" kubernetes.json > tmp && mv tmp kubernetes.json

#show "jq \".properties.linuxProfile.ssh.publicKeys[0].keyData = \\\"\$(cat id_rsa_demo.pub)\\\"\" kubernetes.json > tmp && mv tmp kubernetes.json"
jq ".properties.linuxProfile.ssh.publicKeys[0].keyData = \"$(cat id_rsa_demo.pub)\"" kubernetes.json > tmp && mv tmp kubernetes.json

run "cat kubernetes.json"

desc "Create ARM deployment template and parameters file"
export GOPATH=$(realpath $PWD/../gopath)
run "$GOPATH/bin/acs-engine generate --api-model ./kubernetes.json"

desc "Create deployment"
RESOURCE_GROUP=${DNS_PREFIX}
LOCATION=eastus
DEPLOYMENT_NAME=${DNS_PREFIX}

show "RESOURCE_GROUP=${RESOURCE_GROUP}"
show "DEPLOYMENT_NAME=${DEPLOYMENT_NAME}"
show "LOCATION=$LOCATION"
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

desc "install HELM"
run "curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh"
run "chmod 700 get_helm.sh"
run "./get_helm.sh"
run "helm init --upgrade"
run "kubectl get po --all-namespaces"

desc "Available charts (also visit kubeapps.com and github.com/helm/monocular)"
run "helm search stable"

desc "install Wordpress"
run "helm search wordpress"
#helm search wordpress -l # get all available versions

show "helm inspect stable/wordpress"

show "helm install stable/wordpress"
helm install stable/wordpress --set image=bitnami/wordpress:4.7.4-r1

run "helm list"
run "kubectl get svc"

RELEASE=$(helm list | grep wordpress | awk '{print$1}')

run "kubectl get svc --namespace default ${RELEASE}-wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
run "kubectl get secret --namespace default ${RELEASE}-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode"

show "helm upgrade ${RELEASE} stable/wordpress"
helm upgrade $RELEASE stable/wordpress --set image=bitnami/wordpress:4.7.5-r2

run "kubectl get pods"
run "kubectl get pods"
run "kubectl get svc"
