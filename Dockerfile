FROM alpine:3.23 AS builder

ARG cosign_version=3.0.6
ARG cosign_checksum=c956e5dfcac53d52bcf058360d579472f0c1d2d9b69f55209e256fe7783f4c74
ARG trivy_version=0.70.0
ARG trivy_checksum=8b4376d5d6befe5c24d503f10ff136d9e0c49f9127a4279fd110b727929a5aa9

# Set errexit, nounset, and pipefail shell options for added safety
SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        bash=5.3.3-r1 \
        curl=8.19.0-r0 \
        outils-sha256=0.14-r0

# Download, verify, and install Cosign
RUN curl -fsSLO https://github.com/sigstore/cosign/releases/download/v${cosign_version}/cosign-linux-amd64 && \
    curl -fsSLO https://github.com/sigstore/cosign/releases/download/v${cosign_version}/cosign-linux-amd64.sigstore.json && \
    echo "${cosign_checksum}  cosign-linux-amd64" | sha256sum -c - && \
    install -m 0755 cosign-linux-amd64 /usr/local/bin/cosign && \
    cosign verify-blob \
        --bundle cosign-linux-amd64.sigstore.json \
        --certificate-identity "keyless@projectsigstore.iam.gserviceaccount.com" \
        --certificate-oidc-issuer "https://accounts.google.com" \
        cosign-linux-amd64 && \
    rm -f \
        cosign-linux-amd64 \
        cosign-linux-amd64.sigstore.json

# Download, verify, and install Trivy
RUN curl -fsSLO "https://github.com/aquasecurity/trivy/releases/download/v${trivy_version}/trivy_${trivy_version}_Linux-64bit.tar.gz" && \
    curl -fsSLO "https://github.com/aquasecurity/trivy/releases/download/v${trivy_version}/trivy_${trivy_version}_Linux-64bit.tar.gz.sigstore.json" && \
    echo "${trivy_checksum}  trivy_${trivy_version}_Linux-64bit.tar.gz" | sha256sum -c - && \
    cosign verify-blob \
        --bundle "trivy_${trivy_version}_Linux-64bit.tar.gz.sigstore.json" \
        --certificate-identity "https://github.com/aquasecurity/trivy/.github/workflows/reusable-release.yaml@refs/tags/v${trivy_version}" \
        --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
        "trivy_${trivy_version}_Linux-64bit.tar.gz" && \
    tar -xzf "trivy_${trivy_version}_Linux-64bit.tar.gz" trivy && \
    install -m 0755 trivy /usr/local/bin/trivy && \
    rm -f trivy \
        "trivy_${trivy_version}_Linux-64bit.tar.gz" \
        "trivy_${trivy_version}_Linux-64bit.tar.gz.sigstore.json"

FROM alpine:3.23

# Install package dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
         bash=5.3.3-r1 \
         git=2.52.0-r0\
         jq=1.8.1-r0 \
         openssh=10.2_p1-r0 \
         skopeo=1.20.0-r8

# Install Trivy
COPY --from=builder /usr/local/bin/trivy /usr/local/bin/trivy
