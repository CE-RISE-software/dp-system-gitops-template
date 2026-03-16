# Changelog

All notable changes to the CE-RISE DP System GitOps Template project will be documented in this file.

## [0.0.1] - 03-16-2026

### Added
- Initial deployment template structure for Docker Compose and Kubernetes with Kustomize
- Environment-driven `hex-core-service` deployment baseline with external `io-adapter` as the default mode
- Pinned local registry catalog for CE-RISE model artifacts using explicit artifact URLs
- Local Compose smoke validator in [`scripts/validate-local-compose.sh`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/scripts/validate-local-compose.sh)
- Local Kubernetes smoke validator in [`scripts/validate-local-kubernetes.sh`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/scripts/validate-local-kubernetes.sh)
- Makefile entry points for local template validation
