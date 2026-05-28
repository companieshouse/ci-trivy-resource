# ci-trivy-runner

This project provides a minimal, security-focused Docker image that bundles:

- [Trivy](https://github.com/aquasecurity/trivy) (vulnerability scanner)
- Python runtime
- Supporting tools (`jq`, `skopeo`, `bash`)

## Key Features

- Defence-in-depth verification
    - SHA256 checksum validation (integrity)
    - Sigstore Cosign verification (provenance)
- Multi-stage build - builder stage performs verification, final image contains only trusted artifacts
- Minimal Alpine-based runtime
- Pinned dependencies - reduces drift and improves reproducibility
- Strict shell execution - `errexit`, `nounset`, and `pipefail` options enabled

## Build Overview

### Multi-Stage Design

The `Dockerfile` comprises two stages:

#### 1. Builder stage

Responsible for:

- Downloading binaries ([Cosign](https://github.com/sigstore/cosign), [Trivy](https://github.com/aquasecurity/trivy))
- Verifying integrity (SHA256 checksum) and provenance (Sigstore Cosign verification)
- Installing verified artifacts

This stage includes tools required for validation (e.g. `curl`, `sha256sum`, `cosign`).

#### 2. Final runtime stage

- Based on `python:alpine`
- Installs only required runtime dependencies
- Copies verified Trivy binary from builder

This ensures that the final image does not contain build tools or temporary artifacts, only verified, trusted binaries.

## Supply Chain Security

This project follows a defence-in-depth approach to binary verification.

### 1. Checksum Verification (Integrity)

Each external artifact is verified using a pinned SHA256 checksum:

```shell
echo "${checksum}  file" | sha256sum -c -
```
This ensures:

- The file has not been corrupted
- The downloaded content matches the expected release artifact

### 2. Cosign Verification (Provenance)

After checksum validation, Cosign is used to verify:

- The artifact was signed
- The signature is tied to a trusted identity
- The build originated from a trusted workflow

#### Cosign self-verification

Cosign is verified using Sigstore’s keyless signing:


```shell
cosign verify-blob \
    --bundle cosign-linux-amd64.sigstore.json \
    --certificate-identity "keyless@projectsigstore.iam.gserviceaccount.com" \
    --certificate-oidc-issuer "https://accounts.google.com" \
    ...
```

#### Trivy verification

Trivy is verified against its GitHub Actions release workflow:

```shell
cosign verify-blob \
    --bundle "trivy_${trivy_version}_Linux-64bit.tar.gz.sigstore.json" \
    --certificate-identity "https://github.com/aquasecurity/trivy/.github/workflows/reusable-release.yaml@refs/tags/v${trivy_version}" \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    ...
```

This ensures:

- The artifact was produced by the official project pipeline
- It has not been tampered with after release

## Usage

### Building the image

```shell
docker build -t ci-trivy-runner .
```

## Version Pinning

Key components are explicitly versioned:

```dockerfile
ARG cosign_version=...
ARG trivy_version=...
```

With corresponding checksums:

```dockerfile
ARG cosign_checksum=...
ARG trivy_checksum=...
```

This ensures reproducible builds, controlled upgrade path, and protects against upstream changes.
