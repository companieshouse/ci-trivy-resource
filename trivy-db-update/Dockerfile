FROM alpine:3.14

RUN apk add --no-cache curl && \
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin && \
  trivy image --download-db-only \
