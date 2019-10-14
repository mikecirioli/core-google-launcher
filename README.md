# Overview

This repository contains the GCP Marketplace deployment resources to launch CloudBees Core on Google Container Engine (GKE). 

# Getting Started

## Tool dependencies

- [gcloud](https://cloud.google.com/sdk/)
- [docker](https://docs.docker.com/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/). You can install
  this tool as part of `gcloud`.
- [make](https://www.gnu.org/software/make/)
- [mpdev](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/mpdev-references.md)

## Set Your GCP Config and Authenticate

```shell
gcloud config set project <GCP Project>
gcloud config set compute/zone <zone>
gcloud config set account <user>
gcloud auth login
```
## Google Container Registry (GCR)

A [Makefile](https://github.com/cloudbees/core-google-launcher/blob/master/Makefile) is included, which uses Google Container Registry (GCR). Ensure that GCR is enabled for your project.

[Enable the GCR API](https://console.cloud.google.com/apis/library/containerregistry.googleapis.com)

## Publishing CloudBees Core Images
CloudBees Core images must be published to gcr.io, as they are referenced by the deployer image below.

First, update the variables in the `Makefile` so that they're specific to your environment, then run `make core` to pull/tag/push CloudBees Core Docker images.

## Build and publish the Deployer Image
Build and publish the Deployer [Dockerfile](https://github.com/cloudbees/core-google-launcher/blob/master/Dockerfile) with `make deployer`.

## Create Your Cluster
If you are new to GKE, see [Getting Started](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster) to create your first cluster.

The following commands create a right-sized GKE cluster and install the [Application](https://github.com/kubernetes-sigs/application) Custom Resource Definition (CRD):

```shell
make cluster
```

Note: the Application CRD is required to deploy CloudBees Core.

## Install CloudBees Core on Your Cluster

### Use MPDEV to Install and Test the Deployer Image
Install `mpdev` by using the following [instructions](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/mpdev-references.md).

To install CloudBees Core using `mpdev`, run `make install`. This command has a "watch" at the end to view the progress of the deployment. Use ctrl+c to stop watching.

To view logs for the deployment:

```shell
kubectl logs <deployer image>

ex. kubectl logs cloudbees-core-deployer-kqnr7
```

### Setup Wizard
Get the CloudBees Core Operations Center URL:

```shell
kubectl get ingress -n <namespace> | grep cjoc

ex. kubectl get ingress -n cloudbees-core | grep cjoc
```
Paste the domain name listed into your browser to go to the CloudBees Core Operations Center and start the setup process. Or you can click on the Endpoints link under Kubernetes Engine > Services in the GCP console.

The installation process requires an initial admin password. Execute this command to get it:

```shell
kubectl exec cjoc-0 -n <namespace> -- cat /var/jenkins_home/secrets/initialAdminPassword

ex. kubectl exec cjoc-0 -n cloudbees-core -- cat /var/jenkins_home/secrets/initialAdminPassword
```

Follow the steps in the setup wizard to complete the installation.

### Uninstall CloudBees Core
Run `make uninstall` to uninstall CloudBees Core.

## Using CloudBees Core

### Getting Started Guide
To get started using CloudBees Core read our [Getting Started Guide](https://go.cloudbees.com/docs/cloudbees-core/cloud-admin-guide/getting-started/#).

## DNS
The installation configures a `beesdns.com` domain. To configure a custom DNS, read [Creating DNS Record](https://go.cloudbees.com/docs/cloudbees-core/cloud-install-guide/gke-install/#creating-dns-record).

## HTTPS
The installation configures a self-signed certificate. To configure your own SSL certificate, refer to [Ingress TLS Termination](https://go.cloudbees.com/docs/cloudbees-core/cloud-reference-architecture/ra-for-gke/#_ingress_tls_termination).

## Additional Resources
* [CloudBees Core Administration Guide](https://go.cloudbees.com/docs/cloudbees-core/cloud-admin-guide/)

* [CloudBees Core Reference Architecture](https://go.cloudbees.com/docs/cloudbees-core/cloud-reference-architecture/)

* [Solution Brief](https://pages.cloudbees.com/l/272242/2018-06-26/9sjwj/272242/54721/cloudbees_core.pdf)

## Licensing
A 15-day free trial license is available via the "Request a Trial" button in the Getting Started wizard, however an Internet connection is required to use this option.

If an offline license is needed, send an email to sales@cloudbees.com.

## CloudBees Support
To get Support from CloudBees, [visit the CloudBees Support page](https://support.cloudbees.com/hc/en-us/requests).

## Open Source Jenkins Dedicated Support
[Jenkins Support](https://www.cloudbees.com/products/cloudbees-jenkins-support)