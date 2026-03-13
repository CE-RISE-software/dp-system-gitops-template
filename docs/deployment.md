# Deployment

This template distinguishes between two maturity levels.

## MVP

- Docker Compose is the mandatory working baseline.
- The default deployment points `hex-core-service` at an external HTTP `io-adapter`.
- The default registry source is a local pinned catalog file mounted into the container.

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

## Adapter deployment modes

- External adapter: default and documented baseline.
- Internal adapter slot: supported as an optional extension point, not as the default template path.

## Network assumptions

- `hex-core-service` must be able to reach the configured `io-adapter`.
- `hex-core-service` must be able to fetch model artifacts from the configured registry sources.
