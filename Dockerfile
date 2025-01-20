FROM python:alpine3.14

COPY assets/ /opt/resource/

# Set SHELL flags for RUN commands to allow -e and pipefail
# Rationale: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ARG oras_version=1.2.2

# Pin versions in pip.
# Rationale: https://github.com/hadolint/hadolint/wiki/DL3013
RUN apk update && apk upgrade && \
    apk add --no-cache curl skopeo coreutils && \
    pip install --no-cache-dir requests==2.31.0 && \
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin && \
    curl -LO https://github.com/oras-project/oras/releases/download/v${oras_version}/oras_${oras_version}_linux_amd64.tar.gz && \
    curl -LO https://github.com/oras-project/oras/releases/download/v${oras_version}/oras_${oras_version}_checksums.txt && \
    grep "oras_${oras_version}_linux_amd64.tar.gz" oras_${oras_version}_checksums.txt | sha256sum -c - && \
    tar -xzf oras_${oras_version}_linux_amd64.tar.gz oras && \
    mv oras /usr/local/bin/ && \
    rm oras_${oras_version}_linux_amd64.tar.gz oras_${oras_version}_checksums.txt && \
    apk del curl && \
    chmod +x /opt/resource/*
