FROM gcr.io/cje-marketplace-dev/deployer_envsubst_base:latest

# Update apt
RUN apt-get update
RUN apt-get upgrade

# Install curl
RUN apt-get -y install curl

# Install gcloud
RUN apt-get -y install gnupg2
RUN apt-get -y install lsb-release
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && apt-get install google-cloud-sdk -y

# Download repo files
RUN apt-get -y install git
RUN git clone https://github.com/cloudbees/core-google-launcher.git

COPY deploy/deploy.sh /bin/
COPY deploy/deploy_with_tests.sh /bin/
COPY deploy/schema.yaml /data/
COPY deploy/cje.yml /data/

ENTRYPOINT ["/bin/bash", "/bin/deploy.sh"]
