#Registries
GCR_REGISTRY_PATH=gcr.io/$(GCP_PROJECT)/cloudbees-core-billable
CORE_REGISTRY_PATH=cloudbees
NGINX_REGISTRY_PATH=quay.io/kubernetes-ingress-controller
UBBAGENT_REGISTRY_PATH=gcr.io/cloud-marketplace-tools/metering

#Images
OC_IMAGE_NAME=cloudbees-cloud-core-oc
OC_IMAGE_NAME_PUBLISH=cloudbees-core-billable
MM_IMAGE_NAME=cloudbees-core-mm
NGINX_IMAGE_NAME=nginx-ingress-controller
DEPLOYER_IMAGE_NAME=deployer
UBBAGENT_IMAGE_NAME=ubbagent

#Tags
LATEST_TAG=latest
OC_MM_TAG=2.176.4.3
NGINX_TAG=0.23.0
UBBAGENT_TAG=sha_197574c

#Deployer params
NAME=cloudbees-core
NAMESPACE=cloudbees-core
NUMBER_OF_USERS=10

#New cluster params
CLUSTER_NAME=cloudbees-core-marketplace
REGION=us-east4

# pull/tag/push Core images, build/tag/push Deployer image
all: check-make-params core ubbagent deployer

# These parameters are required for `make`
.PHONY: check-make-params
check-make-params:
	@test -n "$(GCP_PROJECT)" || (echo 'GCP_PROJECT must be set' && exit 1)
	@test -n "$(RELEASE_TAG)" || (echo 'RELEASE_TAG must be set' && exit 1)

# These parameters are required for CJOC licensing
.PHONY: check-license-params
check-license-params:
	@test -n "$(CUSTOMER_FIRST_NAME)" || (echo 'CUSTOMER_FIRST_NAME must be set' && exit 1)
	@test -n "$(CUSTOMER_LAST_NAME)" || (echo 'CUSTOMER_LAST_NAME must be set' && exit 1)
	@test -n "$(CUSTOMER_EMAIL)" || (echo 'CUSTOMER_EMAIL must be set' && exit 1)
	@test -n "$(CUSTOMER_COMPANY)" || (echo 'CUSTOMER_COMPANY must be set' && exit 1)

# build/tag/push Deployer image
.PHONY: deployer
deployer: check-make-params
	docker build \
	-t $(GCR_REGISTRY_PATH)/$(DEPLOYER_IMAGE_NAME):$(LATEST_TAG) \
	-t $(GCR_REGISTRY_PATH)/$(DEPLOYER_IMAGE_NAME):$(RELEASE_TAG) .
	docker push $(GCR_REGISTRY_PATH)/$(DEPLOYER_IMAGE_NAME):$(LATEST_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(DEPLOYER_IMAGE_NAME):$(RELEASE_TAG)

# pull/tag/push CloudBees Core images (sans deployer)
core: check-make-params core-oc core-mm core-nginx

.PHONY: core-oc
core-oc:
	docker pull $(CORE_REGISTRY_PATH)/$(OC_IMAGE_NAME):$(OC_MM_TAG)
	docker tag $(CORE_REGISTRY_PATH)/$(OC_IMAGE_NAME):$(OC_MM_TAG) $(GCR_REGISTRY_PATH):$(OC_MM_TAG)
	docker tag $(CORE_REGISTRY_PATH)/$(OC_IMAGE_NAME):$(OC_MM_TAG) $(GCR_REGISTRY_PATH):$(LATEST_TAG)
	docker tag $(CORE_REGISTRY_PATH)/$(OC_IMAGE_NAME):$(OC_MM_TAG) $(GCR_REGISTRY_PATH):$(RELEASE_TAG)
	docker push $(GCR_REGISTRY_PATH):$(OC_MM_TAG)
	docker push $(GCR_REGISTRY_PATH):$(LATEST_TAG)
	docker push $(GCR_REGISTRY_PATH):$(RELEASE_TAG)

.PHONY: core-mm
core-mm:
	docker pull $(CORE_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(OC_MM_TAG)
	docker tag $(CORE_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(OC_MM_TAG) $(GCR_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(OC_MM_TAG)
	docker tag $(CORE_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(OC_MM_TAG) $(GCR_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(LATEST_TAG)
	docker tag $(CORE_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(OC_MM_TAG) $(GCR_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(RELEASE_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(OC_MM_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(LATEST_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(MM_IMAGE_NAME):$(RELEASE_TAG)

.PHONY: core-nginx
core-nginx:
	docker pull $(NGINX_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(NGINX_TAG)
	docker tag $(NGINX_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(NGINX_TAG) $(GCR_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(NGINX_TAG)
	docker tag $(NGINX_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(NGINX_TAG) $(GCR_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(LATEST_TAG)
	docker tag $(NGINX_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(NGINX_TAG) $(GCR_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(RELEASE_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(NGINX_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(LATEST_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(NGINX_IMAGE_NAME):$(RELEASE_TAG)

# pull/tag/push Google's Usage-based Billing Agent ("ubbagent")
# https://github.com/GoogleCloudPlatform/ubbagent
ubbagent: check-make-params
	docker pull $(UBBAGENT_REGISTRY_PATH)/$(UBBAGENT_IMAGE_NAME):$(UBBAGENT_TAG)
	docker tag $(UBBAGENT_REGISTRY_PATH)/$(UBBAGENT_IMAGE_NAME):$(UBBAGENT_TAG) $(GCR_REGISTRY_PATH)/$(UBBAGENT_IMAGE_NAME):$(UBBAGENT_TAG)
	docker tag $(UBBAGENT_REGISTRY_PATH)/$(UBBAGENT_IMAGE_NAME):$(UBBAGENT_TAG) $(GCR_REGISTRY_PATH)/$(UBBAGENT_IMAGE_NAME):$(LATEST_TAG)
	docker tag $(UBBAGENT_REGISTRY_PATH)/$(UBBAGENT_IMAGE_NAME):$(UBBAGENT_TAG) $(GCR_REGISTRY_PATH)/$(UBBAGENT_IMAGE_NAME):$(RELEASE_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(UBBAGENT_IMAGE_NAME):$(UBBAGENT_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(UBBAGENT_IMAGE_NAME):$(LATEST_TAG)
	docker push $(GCR_REGISTRY_PATH)/$(UBBAGENT_IMAGE_NAME):$(RELEASE_TAG)

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
install: install-app-crd deployer check-license-params
	kubectl create namespace cloudbees-core || true \
	&& mpdev install --deployer=$(GCR_REGISTRY_PATH)/$(DEPLOYER_IMAGE_NAME):$(RELEASE_TAG) \
	--parameters='{"name": "$(NAME)", "namespace": "$(NAMESPACE)", "numberOfUsers": "$(NUMBER_OF_USERS)", \
	"customerFirstName": "$(CUSTOMER_FIRST_NAME)", "customerLastName": "$(CUSTOMER_LAST_NAME)", \
	"customerEmail": "$(CUSTOMER_EMAIL)", "customerCompany": "$(CUSTOMER_COMPANY)", \
	"reportingSecret": "gs://cloud-marketplace-tools/reporting_secrets/fake_reporting_secret.yaml"}'

uninstall:
	kubectl delete ns cloudbees-core
