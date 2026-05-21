FROM python:alpine3.21

COPY assets/ /opt/resource/

ARG cosign_version=3.0.6
ARG cosign_checksum=c956e5dfcac53d52bcf058360d579472f0c1d2d9b69f55209e256fe7783f4c74
ARG trivy_version=0.70.0

# Set SHELL flags for RUN commands to allow -e and pipefail
# Rationale: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Pin versions in pip.
# Rationale: https://github.com/hadolint/hadolint/wiki/DL3013
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
         bash=5.2.37-r0 \
         curl=8.14.1-r2 \
         jq=1.7.1-r0 \
         outils-sha256=0.13-r1 \
         skopeo=1.16.1-r5

# Download, verify, and install Cosign (SHA256 checksum verification)
RUN curl -OL https://github.com/sigstore/cosign/releases/download/v${cosign_version}/cosign-linux-amd64 && \
    echo "${cosign_checksum} cosign-linux-amd64" | sha256sum -c - && \
    install -m 0755 cosign-linux-amd64 /usr/local/bin/cosign && \
    rm cosign-linux-amd64

# Download, verify, and install Trivy (Cosign signature verification)
RUN curl -OL https://github.com/aquasecurity/trivy/releases/download/v${trivy_version}/trivy_${trivy_version}_Linux-64bit.tar.gz && \
    curl -OL https://github.com/aquasecurity/trivy/releases/download/v${trivy_version}/trivy_${trivy_version}_Linux-64bit.tar.gz.sigstore.json && \
    cosign verify-blob \
      --bundle trivy_${trivy_version}_Linux-64bit.tar.gz.sigstore.json \
      --certificate-identity "https://github.com/aquasecurity/trivy/.github/workflows/reusable-release.yaml@refs/tags/v${trivy_version}" \
      --certificate-oidc-issuer https://token.actions.githubusercontent.com \
      trivy_${trivy_version}_Linux-64bit.tar.gz && \
    tar -xzf trivy_${trivy_version}_Linux-64bit.tar.gz --strip-components=0 trivy && \
    install -m 0755 trivy /usr/local/bin/trivy && \
    rm trivy trivy_${trivy_version}_Linux-64bit.tar.gz

# Install Python dependency
RUN pip install --no-cache-dir requests==2.31.0

# Tidy up
RUN apk del curl && chmod +x /opt/resource/*
