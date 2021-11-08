ARG ARGOCD_VERSION=v2.0.4
ARG HELM_SECRETS_VERSION=v3.8.2
ARG SOPS_VERSION=v3.7.1
FROM argoproj/argocd:${ARGOCD_VERSION}
# Switch to root for the ability to perform install
USER root

# Install tools needed for your repo-server to retrieve & decrypt secrets, render manifests
# (e.g. curl, awscli, gpg, sops)
RUN apt-get update && \
    apt-get install -y \
        curl \
        awscli \
        gpg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -o /usr/local/bin/sops -L https://github.com/mozilla/sops/releases/download/v3.7.1/sops-v3.7.1.linux && \
    chmod +x /usr/local/bin/sops

# Switch back to non-root user
USER argocd
RUN helm plugin install https://github.com/jkroepke/helm-secrets --version v3.8.2
# helm secrets plugin should be installed as user argocd or it won't be found
ENV HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/"
