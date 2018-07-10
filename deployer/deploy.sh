#!/bin/bash -eux
#
# Deploys CloudBees Jenkins Enterprise onto Google GKE.
# You can pass in commandline arguments or use environment variables. Commandline arguments take precedent.
# Commandline args:""
#   $1 namespace name
# Environment variables:
#   NAMESPACE
#   SERVICEACCOUNT
#

INGRESS_IP=127.0.0.1 # default...
if test "$#" -eq 2; then
    NAMESPACE_NAME=$1
    SERVICEACCOUNT_NAME=$2
    echo "Using commandline arguments namespace=$NAMESPACE_NAME and serviceaccount=$SERVICEACCOUNT_NAME"
  else
    NAMESPACE_NAME="$namespace"
    SERVICEACCOUNT_NAME="$operatorServiceAccount"
    echo "Using environment var namespace=$NAMESPACE_NAME and serviceaccount=$SERVICEACCOUNT_NAME"
fi

# Convenience method to set CloudBees Jenkins Enterprise Operations Center domain
get_domain_name() {
  echo "$NAMESPACE_NAME.$INGRESS_IP.xip.io"
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

# installs ingress controller if it doesn't already exist
install_ingress_controller(){
if [[ -z $(kubectl get namespace | grep ingress-nginx ) ]]; then
  curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml | kubectl apply -f -
  curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/cloud-generic.yaml | kubectl apply -f -
  echo "Installed ingress controller."
else
  echo "Ingress controller already exists."
fi

  # Set and check the ingress ip
  while [[ "$(kubectl get svc ingress-nginx -n ingress-nginx  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')" = '' ]]; do sleep 3; done
  INGRESS_IP=$(kubectl get svc ingress-nginx -n ingress-nginx  -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | sed 's/"//g')
  echo "NGINX INGRESS: $INGRESS_IP"
}

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

# Main starts here

# Configure GKE cluster to be ready for CJE
# gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$CLUSTER_ZONE_NAME"
 CLUSTERROLES=$(kubectl get clusterrolebinding)
 if echo "$CLUSTERROLES" | grep "cluster-admin-binding"; then
   echo "cluster-admin-binding role exists."
 else
   kubectl create clusterrolebinding cluster-admin-binding  --clusterrole "${SERVICEACCOUNT_NAME}"  --user $(gcloud config get-value account)
   echo "Created role cluster-admin-binding."
 fi

# Install ingress controller and get IP
install_ingress_controller

# Create namespace NOT NEEDED NAMESPACE IS CREATED FOR US
# NAMESPACES=$(kubectl get namespaces)
# if echo "$NAMESPACES" | grep "$NAMESPACE_NAME"; then
#  echo "$NAMESPACE_NAME namespace exists."
# else
#  kubectl create namespace "$NAMESPACE_NAME"
#  kubectl label namespace "$NAMESPACE_NAME" name="$NAMESPACE_NAME"
#  echo "Created namespace $NAMESPACE_NAME."
# fi

# Install CJE
kubectl config set-context $(kubectl config current-context) --namespace="${NAMESPACE_NAME}"
if [ -f $"/data/cje.yml" ]; then
   echo "Installing CJE from /data/cje.yml."
   install_cje "/data/cje.yml"
else
   echo "Installing CJE from ./cje.yml."
   install_cje "./cje.yml"
fi

echo "CloudBees Jenkins Enterprise is installed and running at http://$(get_domain_name)/cjoc."

exit 0
# End of script