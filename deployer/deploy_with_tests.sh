#!/bin/bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

INGRESS_IP=127.0.0.1

set -eox pipefail

get_domain_name() {
  echo "$NAME.$INGRESS_IP.beesdns.com"
}

# Installs CloudBees Core
apply_cloudbees_core_manifest() {
    local manifest_file=${1:?} #first arg should be manifest location
    kubectl apply -f "$manifest_file"
}

# Installs ingress controller
install_ingress_controller() {
    if [[ -z $(kubectl get svc | grep $NAME-ingress-nginx ) ]]; then
      local manifest_file=${1:?} #first arg should be manifest location
      kubectl apply -f "$manifest_file"
      echo "Installed ingress controller."
    else
      echo "Ingress controller already exists."
    fi
    
    while [[ "$(kubectl get svc ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')" = '' ]]; do sleep 3; done
    INGRESS_IP=$(kubectl get svc ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | sed 's/"//g')
    echo "NGINX INGRESS: $INGRESS_IP"
}

# Installs ingress controller op
install_ingress_controller_op() {
    local manifest_file=${1:?} #first arg should be manifest location
    kubectl apply -f "$manifest_file"
    echo "Installed ingress controller on gke op."
}

#create self-signed cert
create_cert(){
  local config_file=/data/server.config

  #override placeholder domain name with actual domain name
  sed -i -e "s#cloudbees-core.example.com#$(get_domain_name)#" "$config_file"

  #create self-signed cert
  openssl req -config "$config_file" -new -newkey rsa:2048 -nodes -keyout server.key -out server.csr
  echo "Created server.key"
  echo "Created server.csr"
  openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
  echo "Created server.crt (self-signed)"

  #create k8s secret which contains cert and key
  kubectl create secret tls $NAME-tls --cert=server.crt --key=server.key
}

deploy_gke_cloud(){
  echo "Deploying onto GKE cloud."
  sed -i '/\$loadBalancerIp/d' "/data/nginx.yaml"
  install_ingress_controller "/data/nginx.yaml"
  create_cert
  sed -i -e "s#\$publicHost#$NAME.$INGRESS_IP.beesdns.com#" "/data/cje.yaml"
  apply_cloudbees_core_manifest "/data/cje.yaml"
}

deploy_gke_op(){
  echo "Deploying onto GKE on-prem."
  install_ingress_controller_op "/data/nginx.yaml"
  sed -i '/tls:/,+3d' "/data/cje.yaml"
  sed -i '/ssl-redirect/d' "/data/cje.yaml"
  sed -i 's/https/http/' "/data/cje.yaml"
  apply_cloudbees_core_manifest "/data/cje.yaml"
}

# If any command returns with non-zero exit code, set -e will cause the script
# to exit. Prior to exit, set App assembly status to "Failed".
handle_failure() {
  code=$?
  if [[ -z "$NAME" ]] || [[ -z "$NAMESPACE" ]]; then
    # /bin/expand_config.py might have failed.
    # We fall back to the unexpanded params to get the name and namespace.
    NAME="$(/bin/print_config.py \
            --xtype NAME \
            --values_mode raw)"
    NAMESPACE="$(/bin/print_config.py \
            --xtype NAMESPACE \
            --values_mode raw)"
    export NAME
    export NAMESPACE
  fi
  patch_assembly_phase.sh --status="Failed"
  exit $code
}

trap "handle_failure" EXIT

NAME="$(/bin/print_config.py \
    --xtype NAME \
    --values_mode raw)"
NAMESPACE="$(/bin/print_config.py \
    --xtype NAMESPACE \
    --values_mode raw)"
export NAME
export NAMESPACE

echo "Deploying application \"$NAME\" in testing mode (mikec!)"

app_uid=$(kubectl get "applications.app.k8s.io/$NAME" \
  --namespace="$NAMESPACE" \
  --output=jsonpath='{.metadata.uid}')
echo "App UID: ${app_uid}"
app_api_version=$(kubectl get "applications.app.k8s.io/$NAME" \
  --namespace="$NAMESPACE" \
  --output=jsonpath='{.apiVersion}')
echo "App API version: ${app_api_version}"

#set values from schema.yaml as environment variables
/bin/expand_config.py --values_mode raw --app_uid "$app_uid"
#merge manifests with environment variables
create_manifests.sh

# Assign owner references for the resources.
/bin/set_ownership.py \
  --app_name "$NAME" \
  --app_uid "$app_uid" \
  --app_api_version "$app_api_version" \
  --manifests "/data/manifest-expanded" \
  --dest "/data/cje.yaml"

/bin/set_ownership.py \
  --app_name "$NAME" \
  --app_uid "$app_uid" \
  --app_api_version "$app_api_version" \
  --manifests "/data/manifest-ingress-expanded" \
  --dest "/data/nginx.yaml"

# Ensure assembly phase is "Pending", until successful kubectl apply.
/bin/setassemblyphase.py \
  --manifest "/data/cje.yaml" \
  --status "Pending"

/bin/setassemblyphase.py \
  --manifest "/data/nginx.yaml" \
  --status "Pending"


if grep -q '$loadBalancerIp' "/data/nginx.yaml" ; then
  deploy_gke_cloud
else
  deploy_gke_op
fi

cjoc_external_ip=""
max_retries=10
retry_count=0

echo "lets check for ingress"

#while [ -z $cjoc_external_ip ] && [ $retry_count -lt $max_retries ]; do
while [ -z $cjoc_external_ip ] && [ $retry_count -lt $max_retries ]; do
#  ((retry_count++))
  let "retry_count=retry_count+1"
  echo "Waiting for ingress..."
  cjoc_external_ip=$(kubectl get ingress | grep cjoc | awk '{ print $2 }')
  [ -z $cjoc_external_ip ] && sleep 10
done
cjoc_url="https://$cjoc_external_ip/cjoc/login?from=%2Fcjoc%2Fteams-check%2F"
#cjoc_url="https://$INGRESS_IP/cjoc/login?from=%2Fcjoc%2Fteams-check%2F"

echo "End point url:  $cjoc_url"

# add some actual tests here
output=""
retry_count=0
while [ -z $output ] && [ $retry_count -lt $max_retries ]; do
  let "retry_count=retry_count+1"
  echo "checking cjoc"
  output=$(curl -L --silent --insecure "$cjoc_url" )
  if [[ $output == *"Unlock CloudBees Core Cloud Operations Center"* ]]; then
    echo "found it this time"
    break
  fi
  output=""
  echo "sleeping......"
  sleep 20
done

echo "tried for $retry_count times" 

if [[ $output != *"Unlock CloudBees Core Cloud Operations Center"* ]]; then
  echo "unable to access jenkins at $cjoc_url"
  exit 1
fi


patch_assembly_phase.sh --status="Success"

clean_iam_resources.sh

trap - EXIT