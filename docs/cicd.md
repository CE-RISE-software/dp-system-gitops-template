# CI/CD

Deployment validation runs locally against the published images. The Forgejo workflow publishes this template's documentation; it does not deploy a running stack.

## Local validation

- validate Compose rendering
- run a local Compose smoke test against the published image
- validate Kustomize rendering
- run a local Kubernetes smoke test against the dev overlay
- run the validation-helper tests with Python's standard library

Repository entry points:

- `Makefile`
- `scripts/validate-local-compose.sh`
- `scripts/validate-local-kubernetes.sh`
- `scripts/validate_see_service.py`

Useful local targets:

- `make validate`
- `make validate-helpers`
- `make validate-compose`
- `make validate-compose-re-indicators`
- `make validate-compose-see-impacts`
- `make validate-compose-calculations`
- `make validate-kubernetes`
- `make validate-kubernetes-re-indicators`
- `make validate-kubernetes-see-impacts`
- `make validate-kubernetes-calculations`

Deployment checks cover configuration rendering, service readiness, initialization, and access to required core schemas. [Operations](operations.md#validation-coverage) documents the checks for each service. The helper tests also check failure reporting and that validation cannot overwrite the operator's Compose environment or remove an existing Kubernetes deployment.

For production-oriented overlays, local validation currently proves deployment and health. End-to-end authenticated functional checks still require real auth infrastructure and credentials.

The local validation scripts assume:

- Docker or a compatible Compose provider is installed
- Python 3 and `curl` are installed
- `kubectl` is installed
- a local Kubernetes cluster is available for the Kubernetes smoke test
- Podman/Docker networking allows outbound DNS and HTTPS from the runtime containers

## Versioned dependencies

Service image references are pinned to the published releases listed in [Configuration](configuration.md#images), consistently across Compose and Kubernetes. Model entries use versioned Codeberg artifact URLs in both catalogs. Keep both deployment formats and model catalogs aligned when updating these dependencies.

## Documentation publishing

The repository uses `mdBook` for documentation publishing.
The existing pages workflow can publish the generated site from `docs/`.

## Release archival

The GitHub mirror creates an archival release when a version tag is pushed. Its release notes are extracted automatically from the matching version heading in `CHANGELOG.md`, with the leading `v` removed from the tag for matching. Missing, duplicate, or empty entries stop release creation. The workflow also links to the canonical Codeberg repository and documentation; it does not build container images, SDKs, or API artifacts.
