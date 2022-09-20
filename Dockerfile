ARG ARGOCD_VERSION=v2.3.2

ARG KSOPS_VERSION=v3.0.1

FROM viaductoss/ksops:$KSOPS_VERSION as ksops-builder

FROM argoproj/argocd:${ARGOCD_VERSION}
# Switch to root for the ability to perform install
USER root

# Install tools needed for your repo-server to retrieve & decrypt secrets, render manifests
# (e.g. curl, awscli, gpg, sops)

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential curl  awscli  gpg && \
    rm -rf /var/lib/apt/lists/*

ARG SOPS_VERSION=v3.7.1

RUN curl -o /usr/local/bin/sops -L https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux && \
    chmod +x /usr/local/bin/sops && /usr/local/bin/sops --version

#configure ksops
# Set the kustomize home directory
ENV XDG_CONFIG_HOME=$HOME/.config
ENV KUSTOMIZE_PLUGIN_PATH=$XDG_CONFIG_HOME/kustomize/plugin/

ARG PKG_NAME=ksops

# Override the default kustomize executable with the Go built version
COPY --from=ksops-builder /go/bin/kustomize /usr/local/bin/kustomize

# Copy the plugin to kustomize plugin path
COPY --from=ksops-builder /go/src/github.com/viaduct-ai/kustomize-sops/*  $KUSTOMIZE_PLUGIN_PATH/viaduct.ai/v1/${PKG_NAME}/


# Switch back to non-root user
USER argocd
ARG HELM_SECRETS_VERSION=v3.10.0

RUN helm plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION}
# helm secrets plugin should be installed as user argocd or it won't be found
ENV HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/"
