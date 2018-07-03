FROM gcr.io/cje-marketplace-dev/deployer_envsubst_base:latest

# CloudBees added (get these from the github repo later)
RUN apt-get update
RUN apt-get upgrade
RUN apt-get -y install git
RUN git clone https://github.com/cloudbees/core-google-launcher.git

COPY deploy/deploy.sh /bin/
COPY deploy/deploy_with_tests.sh /bin/
COPY deploy/schema.yaml /data/
COPY deploy/cje.yml /data/

ENTRYPOINT ["/bin/bash", "/bin/deploy.sh"]
