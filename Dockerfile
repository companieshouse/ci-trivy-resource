FROM python:alpine3.14

COPY assets/ /opt/resource/

# Set SHELL flags for RUN commands to allow -e and pipefail
# Rationale: https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Pin versions in pip.
# Rationale: https://github.com/hadolint/hadolint/wiki/DL3013
RUN apk update && \
    apk upgrade && \
    apk add --no-cache curl skopeo

# Install Python dependency
RUN pip install --no-cache-dir requests==2.31.0

# Install trivy
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Tidy up
RUN apk del curl && chmod +x /opt/resource/*
