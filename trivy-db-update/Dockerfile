FROM alpine:3.14 AS builder

RUN apk add --no-cache curl && \
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin && \
  trivy image --download-db-only

# create a single-layer image from scratch
FROM scratch
COPY --from=builder / /
CMD ["/bin/sh"]
