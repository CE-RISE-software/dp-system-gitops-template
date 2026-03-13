# Operations

This template should support a minimal operator verification checklist.

## Baseline checks

- configuration renders correctly
- `hex-core-service` starts and remains healthy
- registry catalog is mounted and readable
- outbound access to the registry source works
- outbound access to the configured `io-adapter` works
- one authenticated smoke request succeeds

## Compose-oriented checks

Typical checks include:

- `docker compose config`
- `docker compose ps`
- `docker compose logs`

## Kubernetes-oriented checks

Typical checks include:

- `kubectl kustomize`
- `kubectl kustomize k8s/overlays/dev`
- `kubectl kustomize k8s/overlays/prod`
- `kubectl get pods`
- `kubectl logs`
- service and secret presence checks

## Failure domains

Common deployment failures are likely to come from:

- invalid auth configuration
- unreachable or misconfigured `io-adapter`
- registry catalog mismatch
- blocked network egress
- image tag drift
