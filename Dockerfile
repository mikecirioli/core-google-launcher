FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst:latest

# Update apt
RUN apt-get -y update
RUN apt-get -y upgrade

# Install curl
RUN apt-get -y install curl

# Install openssl
RUN apt-get -y install openssl

COPY deployer/create_manifests.sh /bin/
COPY deployer/deploy.sh /bin/
COPY deployer/deploy_with_tests.sh /bin/
COPY schema.yaml /data/
COPY schema-test.yaml /data/schema.yaml
COPY server.config /data/
COPY manifest /data/manifest
COPY manifest-ingress /data/manifest-ingress

ENTRYPOINT ["/bin/bash", "/bin/deploy.sh"]
