FROM gcr.io/cje-marketplace-dev/deployer_envsubst_base:latest

# CloudBees added (get these from the github repo later)
RUN git clone https://github.com/cloudbees/google-core-launcher

COPY deploy/deployer.sh/* /bin/
COPY deploy/deployer_with_tests.sh/* /bin/
COPY deploy/schema.yaml/* /data/
COPY deploy/cje.yml/* /data/

ENTRYPOINT ["/bin/bash", "/bin/deploy.sh"]
