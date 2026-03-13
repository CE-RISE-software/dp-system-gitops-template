# CI/CD

This repository should keep release discipline and documentation publishing simple.
Validation of deployment scaffolding is currently treated as a local operator task rather than a Forgejo runner responsibility.

## Local validation

- validate Compose rendering
- validate Kustomize rendering
- run shell checks if scripts are added

Repository entry points:

- [`Makefile`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/Makefile)
- [`scripts/validate-local.sh`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/scripts/validate-local.sh)

The local validation script assumes:

- Docker or a compatible Compose provider is installed
- `kubectl` is installed if Kustomize rendering should be checked locally

## Release discipline

- update pinned image references as part of template releases
- update pinned model catalog versions as part of template releases
- avoid floating `latest` references in release-ready examples

## Documentation publishing

The repository uses `mdBook` for documentation publishing.
The existing pages workflow can publish the generated site from `docs/`.
