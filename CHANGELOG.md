# Changelog

All notable changes to the CE-RISE DP System GitOps Template project will be documented in this file.

## [0.0.2] - unreleased

### Added
- Optional Compose profile for `re-indicators-calculation-service`
- Optional Kubernetes extension resources for `re-indicators-calculation-service`
- Isolated Kustomize overlays for `dev-re-indicators` and `prod-re-indicators`
- Local Compose validation target for the optional RE indicators path
- Local Kubernetes validation target for the optional RE indicators path
- Documentation page for optional template extensions in [`docs/extensions.md`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/docs/extensions.md)

### Changed
- Updated the shipped model catalog to use `re-indicators-specification` version `0.0.5`
- Extended the local Compose validator to run a real RE indicators compute smoke test when the `re-indicators` profile is enabled
- Extended the local Kubernetes validator to support overlay-specific validation, including RE indicators smoke validation for `dev-re-indicators`
- Clarified that production-oriented Kubernetes overlays are validated locally for deployment and health, while authenticated functional checks still depend on real auth wiring
- Updated README and operator documentation to cover the optional RE indicators deployment path and its validation commands

## [0.0.1] - 03-16-2026

### Added
- Initial deployment template structure for Docker Compose and Kubernetes with Kustomize
- Environment-driven `hex-core-service` deployment baseline with external `io-adapter` as the default mode
- Pinned local registry catalog for CE-RISE model artifacts using explicit artifact URLs
- Local Compose smoke validator in [`scripts/validate-local-compose.sh`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/scripts/validate-local-compose.sh)
- Local Kubernetes smoke validator in [`scripts/validate-local-kubernetes.sh`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/scripts/validate-local-kubernetes.sh)
- Makefile entry points for local template validation
