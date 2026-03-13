# Architecture

This repository is a deployment template for a DP system instance, not an application implementation.

## Component model

- `hex-core-service` is the invariant application component.
- The `io-adapter` is the replaceable HTTP integration boundary used for record storage and external system integration.
- Registry sources provide model artifacts consumed by `hex-core-service`.

## Default deployment pattern

- External clients talk to `hex-core-service`.
- `hex-core-service` talks to the configured `io-adapter` over HTTP.
- `hex-core-service` resolves model artifacts through the configured registry catalog.
- The `io-adapter` is internal-only by default.

## Security boundary

- `hex-core-service` may validate JWTs directly with `AUTH_MODE=jwt_jwks`.
- For HTTP adapters, bearer tokens are expected to be forwarded from `hex-core-service` to the `io-adapter` when present.
- Any `io-adapter` receiving forwarded tokens must be treated as a trusted internal service.

## Deployment milestones

- MVP: working Docker Compose baseline.
- Production template: Docker Compose plus Kubernetes manifests using Kustomize.

## Non-goals

- No frontend UI.
- No DP domain extensions.
- No bundled default adapter implementation in the generic template path.
- No coupling to a single persistence technology.
