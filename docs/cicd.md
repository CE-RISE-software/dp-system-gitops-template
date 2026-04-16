# CI/CD

This repository should keep release discipline and documentation publishing simple.
Validation of deployment scaffolding is currently treated as a local operator task rather than a Forgejo runner responsibility.

## Local validation

- validate Compose rendering
- run a local Compose smoke test against the published image
- validate Kustomize rendering
- run a local Kubernetes smoke test against the dev overlay
- run shell checks if scripts are added

Repository entry points:

- [`Makefile`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/Makefile)
- [`scripts/validate-local-compose.sh`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/scripts/validate-local-compose.sh)
- [`scripts/validate-local-kubernetes.sh`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/scripts/validate-local-kubernetes.sh)

Useful local targets:

- `make validate`
- `make validate-compose`
- `make validate-compose-re-indicators`
- `make validate-kubernetes`
- `make validate-kubernetes-re-indicators`

For production-oriented overlays, local validation currently proves deployment and health. End-to-end authenticated functional checks still require real auth infrastructure and credentials.

The local validation scripts assume:

- Docker or a compatible Compose provider is installed
- `kubectl` is installed
- a local Kubernetes cluster is available for the Kubernetes smoke test
- Podman/Docker networking allows outbound DNS and HTTPS from the runtime containers

## Release discipline

- update pinned image references as part of template releases
- update pinned model catalog versions as part of template releases
- avoid floating `latest` references in release-ready examples

## Documentation publishing

The repository uses `mdBook` for documentation publishing.
The existing pages workflow can publish the generated site from `docs/`.
