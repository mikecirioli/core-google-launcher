# Overview

Repository with scripts to configure and launch CloudBees Core on GKE.

# Getting Started

## Set Your GCP Config and Authenticate

```shell
gcloud config set project <GCP Project>
gcloud config set compute/zone <zone>
gcloud config set account <user>
gcloud auth login
```

## Create Your Cluster

See [Getting Started](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/README.md#getting-started) to create your cluster. CloudBees Jenkins Enterprise requires a minimum 3 node cluster with each node having a minimum of 2 vCPU and k8s version 1.8.

Then:

```shell
gcloud container clusters get-credentials <cluster> 
```

## Installing CloudBees Jenkins Enterprise on Your Cluster

### Create your Namespace
```shell
kubectl create <namespace>
export NAMESPACE=<namespace>
```

### One-time CRD Setup

```shell
make crd/install
```

### Install CloudBees Jenkins Enterprise on your Cluster

```shell
make app/install
```

### Monitor the Installation

```shell
make app/watch
```
### Delete the Installation

```shell
make app/uninstall
```


