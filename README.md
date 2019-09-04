# Overview

This repository contains the GCP Marketplace deployment resources to launch CloudBees Core on Google Container Enginer (GKE). 

# Getting Started

## Tool dependencies

- [gcloud](https://cloud.google.com/sdk/)
- [docker](https://docs.docker.com/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/). You can install
  this tool as part of `gcloud`.
- [jq](https://github.com/stedolan/jq/wiki/Installation)
- [make](https://www.gnu.org/software/make/)
- [watch command](https://en.wikipedia.org/wiki/Watch_(Unix))

## Set Your GCP Config and Authenticate

```shell
gcloud config set project <GCP Project>
gcloud config set compute/zone <zone>
gcloud config set account <user>
gcloud auth login
```
## Google Container Registry (GCR)

Make files are set up to use Google Container Registry (GCR). Ensure that you GCR enabled for your project. 

[Enable the GCR API](https://console.cloud.google.com/apis/library/containerregistry.googleapis.com)

## Building the Deployer Image
Build from the [Dockerfile](https://github.com/cloudbees/core-google-launcher/blob/master/Dockerfile).

```shell
docker build -t deployer:latest .

docker tag deployer:latest gcr.io/<path>/deployer:<tag>

docker push gcr.io/<path>/deployer:<tag>
```

## Create Your Cluster

See [Getting Started](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster) to create your cluster. CloudBees Core requires a minimum 3 node cluster with each node having a minimum of 2 vCPU and k8s version 1.8.

Then:

```shell
gcloud container clusters get-credentials <cluster> 
```

## Installing CloudBees Core on Your Cluster

### Use MPDEV to Install and Test Your Deployer Image
[MPDEV from Google](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/mpdev-references.md)

### Setup Wizard
Get the CloudBees Core Operations Center URL:

```shell
kubectl get ing -n <namespace> | grep cjoc

ex. kubectl get ing -n deployer-test | grep cjoc
```
Paste the domain name listed into your browser to go to the CloudBees Core Operations Center and start the setup process. Or you can click on the cjoc Endpoints link under Kubernetes Engine > Services in the GCP console.

The installation process requires an intial admin password. Execute this command to get it:

```shell
kubectl exec <app name>-cjoc-0 -n <namespace> -- cat /var/jenkins_home/secrets/initialAdminPassword

ex. kubectl exec cloudbees-core-1-cjoc-0 -n deployer-test -- cat /var/jenkins_home/secrets/initialAdminPassword
```

You can use the Connect button at Kubernetes Engine > Clusters to launch Cloud Shell to issue this command.

Follow the steps in the setup wizard to complete the installation.

## Using CloudBees Core

### Getting Started Guide
To get started using CloudBees Core read our [Getting Started Guide](https://go.cloudbees.com/docs/cloudbees-core/cloud-admin-guide/getting-started/#).

## DNS
The installation configures an xip.io domain. To configure a custom DNS, read [Creating DNS Record](https://go.cloudbees.com/docs/cloudbees-core/cloud-install-guide/gke-install/#creating-dns-record).

## HTTPS
The installation configures a self-signed certificate. To configure your own SSL certificate, read [Ingress TLS Termination](https://go.cloudbees.com/docs/cloudbees-core/cloud-reference-architecture/ra-for-gke/#_ingress_tls_termination).

## Additional Resources
* [CloudBees Core Administration Guide](https://go.cloudbees.com/docs/cloudbees-core/cloud-admin-guide/)

* [CloudBees Core Reference Architecture](https://go.cloudbees.com/docs/cloudbees-core/cloud-reference-architecture/)

* [Solution Brief](https://pages.cloudbees.com/l/272242/2018-06-26/9sjwj/272242/54721/cloudbees_core.pdf)

## Licensing
Request a license by sending an email to info@cloudbees.com or support@cloudbees.com.

## CloudBees Support
For CloudBees support, [visit the CloudBees support page](https://support.cloudbees.com/hc/en-us/requests).

## Open Source Jenkins Dedicated Support
[Jenkins Support](https://www.cloudbees.com/products/cloudbees-jenkins-support)

## Delete the Installation (optional)

```shell
make app/uninstall
```
or

```shell
kubectl delete application <application> -n <namespace>
```

