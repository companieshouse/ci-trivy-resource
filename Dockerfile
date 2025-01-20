FROM python:alpine3.14

COPY assets/ /opt/resource/

# Set SHELL flags for RUN commands to allow -e and pipefail
# Rationale: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Pin versions in pip.
# Rationale: https://github.com/hadolint/hadolint/wiki/DL3013
RUN apk update && apk upgrade && \
    apk add --no-cache curl skopeo && \
    pip install --no-cache-dir requests==2.31.0 && \
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin && \
    curl -LO https://github.com/oras-project/oras/releases/download/v1.2.2/oras_1.2.2_linux_amd64.tar.gz && \
    tar -xzf oras_1.2.2_linux_amd64.tar.gz oras && \
    mv oras /usr/local/bin/ && \
    rm oras_1.2.2_linux_amd64.tar.gz && \
    apk del curl && \
    chmod +x /opt/resource/*
