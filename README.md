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

A `Makefile` is included which pushes Docker images Google Container Registry (GCR). Ensure that GCR is enabled for your project by navigating to [GCR](https://console.cloud.google.com/apis/library/containerregistry.googleapis.com) and activating it if it's not already activated.

The `Makefile` references GCR by project name. Set an environment variable for your GCP project:

`export GCP_PROJECT=my-gcp-project`

The `Makefile` tags images before pushing them to GCR. Most images have unique tags, but a `RELEASE_TAG` is shared across all images and must be set as an environment variable:

`export RELEASE_TAG=2.176`

**Important**: `schema.yaml` contains default values for Docker image locations and tags, and these values are used as-is during the deployment. While not required, it is possible to publish CloudBees Core images to your own registry and use them during the deployment. To use your own images, follow the optional publishing steps below, then manually update the Docker image references in `schema.yaml` prior to installation.

## Publish All Images (Optional)

Run `make` to publish all images.

## Publish CloudBees Core Images (Optional)

Run `make core` to pull/tag/push [CloudBees Core Docker images](https://hub.docker.com/u/cloudbees).

## Publish Marketplace-specific Images (Optional)

Run `make ubbagent` to publish Google's [Usage-based billing agent](https://github.com/GoogleCloudPlatform/ubbagent) ("ubbagent").

**Note**: `imageReportingFunction` is a marketplace-specific image that's published separately by CloudBees.

## Build and publish the Deployer Image (Optional)

Build and publish the deployer `Dockerfile` with `make deployer`.

**Note**: the deployer image must be built every time deployment code changes. For convenience, the deployer image is built by `make install`, discussed below.

## Create Your Cluster
If you are new to GKE, see [Getting Started](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster) to create your first cluster.

The following command automatically creates a GKE cluster and updates your `kubectl` configuration to point to the newly created cluster:

```shell
make cluster
```

**Note**: the [Application](https://github.com/kubernetes-sigs/application) Custom Resource Definition (CRD) is required to install CloudBees Core. It is installed automatically with the `make install` command, discussed below.

## Install CloudBees Core on Your Cluster

### Set required licensing parameters

The following environment variables need to be set:
- CUSTOMER_FIRST_NAME  -  _Your first name_
- CUSTOMER_LAST_NAME  -  _Your last name_
- CUSTOMER_EMAIL  -  _Your email address_
- CUSTOMER_COMPANY  -  _Your company name_

### Use `mpdev` to Install and Test the Deployer Image
Install `mpdev` by using the following [instructions](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/mpdev-references.md).

To install CloudBees Core using `mpdev`, run `make install`.

When the `mpdev` command is finished, watch the installation proceed using `kubectl get po -w -n cloudbees-core`.

The installation is complete when the status of the deployer image is `Completed`, but be mindful of the status of the other pods. The deployer running to completion doesn't always mean the install was successful. The installation is (generally) successful when the deployer image status is `Completed` and there are 3/3 containers running in the `cjoc-0` pod.

To view logs for the deployment:

```shell
kubectl logs <deployer image> -n <namespace>

ex. kubectl logs cloudbees-core-deployer-kqnr7 -n cloudbees-core
```

### Setup Wizard
Get the CloudBees Core Operations Center URL:

```shell
kubectl get ingress -n <namespace> | grep cjoc

ex. kubectl get ingress -n cloudbees-core | grep cjoc
```

Paste the domain name listed into your browser to go to CloudBees Core Operations Center and start the setup process. Or you can click on the Endpoints link under Kubernetes Engine > Services in the GCP console.

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

## CloudBees Support
To get Support from CloudBees, [visit the CloudBees Support page](https://support.cloudbees.com/hc/en-us/requests).

## Open Source Jenkins Dedicated Support
[Jenkins Support](https://www.cloudbees.com/products/cloudbees-jenkins-support)