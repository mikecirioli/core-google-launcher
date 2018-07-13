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

# Convenience method to retry a command several times
retry_command() {
  local max_attempts=${ATTEMPTS-60}
  local timeout=${TIMEOUT-1}
  local attempt=0
  local exitCode=0

  while (( $attempt < $max_attempts ))
  do
    set +e
    "$@"
    exitCode=$?
    set -e

    if [[ $exitCode == 0 ]]
    then
      break
    fi

    echo "$(date -u '+%T') Failure ($exitCode) Retrying in $timeout seconds..." 1>&2
    sleep $timeout
    attempt=$(( attempt + 1 ))
    timeout=$(( timeout ))
  done

  if [[ $exitCode != 0 ]]
  then
    echo "$(date -u '+%T') Failed in the last attempt ($@)" 1>&2
  fi

  return $exitCode
}

get_domain_name() {
  echo "$NAME.$INGRESS_IP.xip.io"
}

# Installs CloudBees Jenkins Enterprise
install_cje() {
    local source=${1:?}
    local install_file; install_file=$(mktemp)
    cp $source $install_file
    
    # Set domain
    sed -i -e "s#cje.example.com#$(get_domain_name)#" "$install_file"
    kubectl apply -f "$install_file"

    echo "Waiting for CJE to start"
    TIMEOUT=10 retry_command curl -sSLf -o /dev/null http://$(get_domain_name)/cjoc/login
}

# Installs ingress controller
install_ingress_controller() {
    if [[ -z $(kubectl get svc | grep ingress-nginx ) ]]; then
      local source=${1:?}
      local install_file; install_file=$(mktemp)
      cp $source $install_file
      kubectl apply -f "$install_file"
      echo "Installed ingress controller."
    else
      echo "Ingress controller already exists."
    fi
    
    
    while [[ "$(kubectl get svc ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')" = '' ]]; do sleep 3; done
    INGRESS_IP=$(kubectl get svc ingress-nginx  -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | sed 's/"//g')
    echo "NGINX INGRESS: $INGRESS_IP"
}

# This is the entry point for the production deployment

# If any command returns with non-zero exit code, set -e will cause the script
# to exit. Prior to exit, set App assembly status to "Failed".
handle_failure() {
  code=$?
  if [[ -z "$NAME" ]] || [[ -z "$NAMESPACE" ]]; then
    # /bin/expand_config.py might have failed.
    # We fall back to the unexpanded params to get the name and namespace.
    NAME="$(/bin/print_config.py --param '{"x-google-marketplace": {"type": "NAME"}}' \
            --values_file /data/values.yaml --values_dir /data/values)"
    NAMESPACE="$(/bin/print_config.py --param '{"x-google-marketplace": {"type": "NAMESPACE"}}' \
                 --values_file /data/values.yaml --values_dir /data/values)"
    export NAME
    export NAMESPACE
  fi
  patch_assembly_phase.sh --status="Failed"
  exit $code
}
trap "handle_failure" EXIT

/bin/expand_config.py
NAME="$(/bin/print_config.py --param '{"x-google-marketplace": {"type": "NAME"}}')"
NAMESPACE="$(/bin/print_config.py --param '{"x-google-marketplace": {"type": "NAMESPACE"}}')"
export NAME
export NAMESPACE

echo "Deploying application \"$NAME\""

app_uid=$(kubectl get "applications/$NAME" \
  --namespace="$NAMESPACE" \
  --output=jsonpath='{.metadata.uid}')
app_api_version=$(kubectl get "applications/$NAME" \
  --namespace="$NAMESPACE" \
  --output=jsonpath='{.apiVersion}')

create_manifests.sh

###ingress-controller creation###
# Assign owner references for the resources.
/bin/set_ownership.py \
  --app_name "$NAME" \
  --app_uid "$app_uid" \
  --app_api_version "$app_api_version" \
  --manifests "/data/manifest-ingress-expanded" \
  --dest "/data/ingress-controller.yaml"

# Ensure assembly phase is "Pending", until successful kubectl apply.
/bin/setassemblyphase.py \
  --manifest "/data/ingress-controller.yaml" \
  --status "Pending"

install_ingress_controller "/data/ingress-controller.yaml"

###cje###
# Assign owner references for the resources.
/bin/set_ownership.py \
  --app_name "$NAME" \
  --app_uid "$app_uid" \
  --app_api_version "$app_api_version" \
  --manifests "/data/manifest-expanded" \
  --dest "/data/cje.yaml"

# Ensure assembly phase is "Pending", until successful kubectl apply.
/bin/setassemblyphase.py \
  --manifest "/data/cje.yaml" \
  --status "Pending"

install_cje "/data/cje.yaml"

echo "CloudBees Jenkins Enterprise is installed and running at http://$(get_domain_name)/cjoc."

# Test #1 console validation
if curl -s "http://$(get_domain_name)/cjoc/login" | grep "Unlock Jenkins"; then
  echo "CloudBees Jenkins Enterprise launched successfully."
  exit 0
else
  echo "CloudBees Jenkins Enterprise failed to launch. CJOC not available."
  exit 1
fi

# Test #2 check initial password
initialAdminPassword=$(kubectl exec cjoc-0 -- cat /var/jenkins_home/secrets/initialAdminPassword)
if [ -z "$initialAdminPassword"]; then
  echo "CloudBees Jenkins Enterprise failed to launch"
    exit 1
else
  echo "CloudBees Jenkins Enterprise launched successfully."
  exit 0
fi

patch_assembly_phase.sh --status="Success"

clean_iam_resources.sh

trap - EXIT
