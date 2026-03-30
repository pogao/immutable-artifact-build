# Immutable Artifact Build

A supply chain security reference implementation that achieves [SLSA Level 3](https://slsa.dev/spec/v1.0/levels) compliance using Nix Flakes for hermetic, reproducible builds and Google Cloud Build for provenance attestation.

## What This Project Demonstrates

The Go application itself — a simple HTTP service that detects leaked secrets using [gitleaks](https://github.com/zricethezav/gitleaks) — is intentionally minimal. The real focus is the **build and delivery pipeline**: a fully reproducible, tamper-evident artifact supply chain built on two key technologies.

### Hermetic Builds with Nix Flakes

The entire build — from Go compilation to Docker image creation — is defined declaratively in a [Nix flake](flake.nix). This gives us properties that traditional CI pipelines struggle to guarantee:

- **Bit-for-bit reproducibility** — the same flake lock produces the same image bytes on any machine, eliminating "works on my machine" drift between local dev and CI.
- **No implicit dependencies** — unlike multi-stage Dockerfiles that pull from mutable base images, every input (Go toolchain, CA certificates, libc) is pinned by content hash in `flake.lock`.
- **Minimal attack surface** — `dockerTools.buildLayeredImage` produces a distroless-style image with no shell, no package manager, and no OS layer. Only the binary and CA certs are included.

### SLSA Level 3 via Cloud Build

The [Cloud Build pipeline](cloudbuild.yaml) implements the SLSA v1.0 Build Track requirements:

| SLSA Requirement | Implementation |
|---|---|
| **Build as code** | Pipeline defined in version-controlled `cloudbuild.yaml` |
| **Verified provenance** | `requestedVerifyOption: VERIFIED` generates signed, non-falsifiable provenance metadata |
| **Hardened builds** | Cloud Build runs in an ephemeral, isolated VM — no persistent state, no user SSH access |
| **Parameterless** | Build is fully determined by source; no runtime parameters influence the output |
| **SBOM generation** | [Syft](https://github.com/anchore/syft) produces a CycloneDX SBOM linked to the image by digest |
| **SBOM attestation** | SBOM is uploaded to Artifact Registry and associated with the image via `gcloud artifacts sbom load` |

The pipeline pushes to Google Artifact Registry and references images **by digest, not tag**, ensuring that the SBOM and provenance always refer to the exact image that was built — never a later overwrite.

## Architecture

```
Source (GitHub)
  │
  ▼
Cloud Build (ephemeral VM)
  │
  ├─ Step 1: nix build → deterministic .tar.gz image
  ├─ Step 2: docker load/tag/push → Artifact Registry (by digest)
  ├─ Step 3: syft scan → CycloneDX SBOM
  └─ Step 4: gcloud artifacts sbom load → SBOM attestation
  │
  ▼
Artifact Registry
  ├─ Container image (signed provenance)
  └─ SBOM (linked by digest)
```

## The Application

The bundled service exposes a single endpoint:

```
POST /api
Content-Type: application/json

{"value": "AKIAIOSFODNN7EXAMPLE"}
```

It runs the input through gitleaks' detection engine and returns whether the value matches known secret patterns (AWS keys, GitHub tokens, API keys, etc.). Useful as a pre-commit webhook or integration point for secret scanning workflows.

## Local Development

Prerequisites: [Nix](https://nixos.org/download/) with flakes enabled.

```bash
# Enter the dev shell (Go + golangci-lint)
nix develop

# Run tests
go test ./...

# Build the Docker image locally
nix build

# Load and run
docker load < result
docker run -p 8080:8080 leaks-finder
```

## Why This Matters

Software supply chain attacks (SolarWinds, Codecov, xz-utils) have shown that securing the build pipeline is as critical as securing the code. This project demonstrates a practical approach to the problem: deterministic builds that anyone can verify, signed provenance that proves where an artifact came from, and an SBOM that documents exactly what's inside it.
