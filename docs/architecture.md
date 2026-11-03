# Architecture

This repository is a deployment template for a DP system instance, not an application implementation.

## Component model

- `hex-core-service` is the invariant application component.
- The `io-adapter` is the replaceable HTTP integration boundary used for record storage and external system integration.
- Optional downstream application services may depend on `hex-core-service` without becoming part of the `io-adapter` boundary.
- Registry sources provide model artifacts consumed by `hex-core-service`.

## Default deployment pattern

- External clients talk to `hex-core-service`.
- `hex-core-service` talks to the configured `io-adapter` over HTTP.
- `hex-core-service` resolves model artifacts through the configured registry catalog.
- The `io-adapter` is internal-only by default.

## Calculation services

RE Indicators and SEE Impacts are optional HTTP services. They use HEX Core for data-model validation without changing the core-to-adapter contract. They can run separately or together, with one shared core deployment.

SEE accepts Product System and LCI Dataset records and returns an Integrated LCA result containing all 25 configured EF 3.1 indicators. Its image includes the BONSAI background and characterization factors. Each calculation runs in an isolated temporary Brightway project created from that background. The template supplies deployment configuration and model registration; applications consuming the result decide whether and where to store it.

## Security boundary

- `hex-core-service` may validate JWTs directly with `AUTH_MODE=jwt_jwks`.
- For HTTP adapters, bearer tokens are expected to be forwarded from `hex-core-service` to the `io-adapter` when present.
- Any `io-adapter` receiving forwarded tokens must be treated as a trusted internal service.
- SEE is reachable through the Compose network and a loopback-only host port, or a Kubernetes ClusterIP service. Its bearer token authenticates outgoing HEX Core requests, not incoming API calls. Remote access requires an authenticated reverse proxy or ingress.

## Deployment targets

- Docker Compose baseline with optional calculation-service profiles.
- Kubernetes manifests using Kustomize, with development, production, and optional calculation-service overlays.

## Non-goals

- No frontend UI.
- No DP domain extensions.
- No bundled default adapter implementation in the generic template path.
- No coupling to a single persistence technology.
