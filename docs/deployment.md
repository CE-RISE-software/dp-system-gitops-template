# Deployment

This template distinguishes between two maturity levels.

## MVP

- Docker Compose is the mandatory working baseline.
- The default deployment points `hex-core-service` at an external HTTP `io-adapter`.
- The default registry source is a local pinned catalog file mounted into the container.
- The catalog uses explicit per-artifact URLs for each model entry.

Baseline structure:

- [`compose/docker-compose.yml`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/compose/docker-compose.yml)
- [`compose/.env.example`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/compose/.env.example)
- [`compose/registry/catalog.json`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/compose/registry/catalog.json)

## Production template

- Kubernetes manifests are included using Kustomize.
- Secret handling is part of the production template path.
- Operators may replace plain secret manifests with Sealed Secrets, SOPS, or external secret managers.

Baseline structure:

- [`k8s/base/kustomization.yaml`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/k8s/base/kustomization.yaml)
- [`k8s/base/hex-core-deployment.yaml`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/k8s/base/hex-core-deployment.yaml)
- [`k8s/base/registry-configmap.yaml`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/k8s/base/registry-configmap.yaml)
- [`k8s/base/auth-secret.example.yaml`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/k8s/base/auth-secret.example.yaml)
- [`k8s/overlays/dev/kustomization.yaml`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/k8s/overlays/dev/kustomization.yaml)
- [`k8s/overlays/prod/kustomization.yaml`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/k8s/overlays/prod/kustomization.yaml)

## Adapter deployment modes

- External adapter: default and documented baseline.
- Internal adapter slot: supported as an optional extension point, not as the default template path.

## Optional downstream services

The template may also host optional services that sit beside `hex-core-service` and use it as an application dependency.

- `re-indicators-calculation-service` is supported as an isolated Compose extension profile.
- `re-indicators-calculation-service` is also supported through isolated Kustomize overlays.
- This service is not part of the `io-adapter` boundary and should not reshape the baseline core deployment path.
- The optional Compose profile and Kubernetes overlays depend on `hex-core-service` and the published `re-indicators-specification` artifacts.

## Development overlay

The repository now includes a minimal development overlay:

- dedicated namespace
- debug logging
- example cluster-local adapter URL override
- insecure auth mode for development only

This overlay is not the production security model. It exists to make local and early-cluster testing easier.

## Production overlay

The repository also includes a minimal production-oriented overlay:

- dedicated production namespace
- `jwt_jwks` authentication path
- example auth secret manifest
- replica count and resource requests/limits

This overlay is still a template starting point. Operators are expected to replace example secret material and environment-specific endpoints.

## Network assumptions

- `hex-core-service` must be able to reach the configured `io-adapter`.
- `hex-core-service` must be able to fetch model artifacts from the configured registry sources.
