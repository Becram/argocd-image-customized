ARG ARGOCD_VERSION=v2.14.3

ARG KSOPS_VERSION=v4.3.3

ARG HELM_VERSION=v3.17.0


FROM viaductoss/ksops:$KSOPS_VERSION AS ksops-builder

FROM quay.io/argoproj/argocd:${ARGOCD_VERSION}
# Switch to root for the ability to perform install
USER root

# Install tools needed for your repo-server to retrieve & decrypt secrets, render manifests
# (e.g. curl, awscli, gpg, sops)

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential curl  gpg unzip && \
    rm -rf /var/lib/apt/lists/*


# Install AWS CLI v2
ADD https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip awscliv2.zip
RUN unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip && \
    aws --version


ARG SOPS_VERSION=v3.9.4
ADD  https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64  /usr/local/bin/sops
RUN chmod +x /usr/local/bin/sops && /usr/local/bin/sops --version

#configure ksops
# Set the kustomize home directory
ENV XDG_CONFIG_HOME=$HOME/.config
ENV KUSTOMIZE_PLUGIN_PATH=$XDG_CONFIG_HOME/kustomize/plugin/

ARG PKG_NAME=ksops

# Override the default kustomize executable with the Go built version
COPY --from=ksops-builder /go/bin/kustomize /usr/local/bin/kustomize

# Copy the plugin to kustomize plugin path

RUN curl -fsSL https://raw.githubusercontent.com/viaduct-ai/kustomize-sops/master/scripts/install-ksops-archive.sh | bash
# COPY --from=ksops-builder /go/src/github.com/viaduct-ai/kustomize-sops/*  $KUSTOMIZE_PLUGIN_PATH/viaduct.ai/v1/${PKG_NAME}/

# RUN curl -o /tmp/helm-linux-amd64.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz  && \
#     tar -xvf /tmp/helm-linux-amd64.tar.gz && ls /tmp/
# Switch back to non-root user
USER 999
ARG HELM_SECRETS_VERSION=v4.6.3

RUN helm plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION}
# helm secrets plugin should be installed as user argocd or it won't be found
ENV HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/"
