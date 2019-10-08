#Registries
CORE_REGISTRY_PATH=cloudbees
NGINX_REGISTRY_PATH=quay.io/kubernetes-ingress-controller
GCP_PROJECT=cje-marketplace-dev
GCR_REGISTRY_PATH=gcr.io/$(GCP_PROJECT)/cloudbees-core

#Images
OC_IMAGE_NAME=cloudbees-cloud-core-oc
OC_IMAGE_NAME_PUBLISH=cloudbees-core
MM_IMAGE_NAME=cloudbees-core-mm
NGINX_IMAGE_NAME=nginx-ingress-controller
DEPLOYER_IMAGE_NAME=deployer

#Tags
OC_MM_TAG=2.176.4.3
NGINX_TAG=0.23.0
DEPLOYER_TAG=latest

#Deployer params
NAME=cloudbees-core
NAMESPACE=cloudbees-core

#New cluster params
CLUSTER_NAME=cloudbees-core-marketplace
REGION=us-east4

# pull/tag/push Core images, build/tag/push Deployer image
all: core deployer

# build/tag/push Deployer image
.PHONY: deployer
deployer:
	docker build -t $(DEPLOYER_IMAGE_NAME):$(DEPLOYER_TAG) . \
	&& docker tag $(DEPLOYER_IMAGE_NAME):$(DEPLOYER_TAG) $(GCR_REGISTRY_PATH)/$(DEPLOYER_IMAGE_NAME):$(DEPLOYER_TAG) \
	&& docker push $(GCR_REGISTRY_PATH)/$(DEPLOYER_IMAGE_NAME):$(DEPLOYER_TAG)

# pull/tag/push CloudBees Core images
core: core-oc core-mm core-nginx

.PHONY: core-oc
core-oc:
	docker pull $(CORE_REGISTRY_PATH)/$(OC_IMAGE_NAME):$(OC_MM_TAG)
	docker tag $(CORE_REGISTRY_PATH)/$(OC_IMAGE_NAME):$(OC_MM_TAG) $(GCR_REGISTRY_PATH):$(OC_MM_TAG)
	docker push $(GCR_REGISTRY_PATH):$(OC_MM_TAG)

.PHONY: core-mm
core-mm:
	docker pull $(CORE_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(OC_MM_TAG)
	docker tag $(CORE_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(OC_MM_TAG) $(GCR_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(OC_MM_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(OC_MM_TAG)

.PHONY: core-nginx
core-nginx:
	docker pull $(NGINX_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(NGINX_TAG)
	docker tag $(NGINX_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(NGINX_TAG) $(GCR_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(NGINX_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(NGINX_TAG)

# create a new cluster
.PHONY: cluster
cluster:
	gcloud container clusters create $(CLUSTER_NAME) \
	--region $(REGION) \
	--machine-type n1-standard-2 \
	--enable-autoscaling \
	--num-nodes 1 \
	--max-nodes 2 

# install kubernetes-sigs/application CRD (required)
.PHONY: install-app-crd
install-app-crd:
	kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"

# install CloudBees Core using mpdev:
# https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/mpdev-references.md
install: install-app-crd
	kubectl create namespace cloudbees-core || true \
	&& mpdev install --deployer=$(GCR_REGISTRY_PATH)/$(DEPLOYER_IMAGE_NAME):$(DEPLOYER_TAG) \
	--parameters='{"name": "$(NAME)", "namespace": "$(NAMESPACE)"}' \
	&& kubectl get po -w

uninstall:
	kubectl delete ns cloudbees-core