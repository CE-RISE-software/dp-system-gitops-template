# Operations

Use the checks below to verify configuration, service readiness, and access to model artifacts.

## Baseline checks

- configuration renders correctly
- `hex-core-service` starts and remains healthy
- registry catalog is mounted and readable
- outbound access to the registry source works
- outbound access to the configured `io-adapter` works
- one authenticated smoke request succeeds

## Compose-oriented checks

Typical checks include:

- `./scripts/validate-local-compose.sh`
- `COMPOSE_PROFILES=re-indicators ./scripts/validate-local-compose.sh`
- `make validate-compose-see-impacts`
- `make validate-compose-calculations`

The validator creates a temporary configuration and a uniquely named Compose project, then removes its own containers on exit. It does not overwrite `compose/.env` or stop an operator's stack. Ports still need to be free; use `HEX_CORE_PORT`, `RE_INDICATORS_CALC_PORT`, and `SEE_IMPACTS_CALC_PORT` in the shell environment to select alternative validation ports. The validation core uses development-only unauthenticated mode.

To inspect an existing SEE deployment, run from `compose/`:

```bash
docker compose --profile see-impacts ps
docker compose --profile see-impacts logs see-impacts-calculation-service
curl --fail http://localhost:8084/health
curl --fail http://localhost:8084/capabilities
curl --fail http://localhost:8084/methods
```

Use the configured host port if it differs from the default.

## Kubernetes-oriented checks

Typical checks include:

- `./scripts/validate-local-kubernetes.sh`
- `K8S_OVERLAY=dev-re-indicators ./scripts/validate-local-kubernetes.sh`
- `K8S_OVERLAY=prod-re-indicators ./scripts/validate-local-kubernetes.sh`
- `make validate-kubernetes-see-impacts`
- `make validate-kubernetes-calculations`

The Kubernetes validator needs a running cluster and permission to create resources. It creates the selected namespace (`dp-system-dev` or `dp-system-prod`) and removes its resources on exit. It refuses to proceed if that namespace already exists, so it cannot be run against an existing deployment. Use `kubectl kustomize` for rendering-only checks without a cluster.

For example, to inspect an existing development SEE deployment:

```bash
kubectl get pods -n dp-system-dev
kubectl logs -n dp-system-dev deployment/see-impacts-calculation-service
kubectl port-forward -n dp-system-dev service/see-impacts-calculation-service 18084:8080
```

With the port forward running, the SEE endpoints are available at `http://localhost:18084`.

## SEE validation coverage

The SEE checks verify:

- `/health` identifies a healthy SEE service.
- `/capabilities` opens the bundled `BONSAI` and `ef31_biosphere` databases.
- `/methods` returns non-empty, unique method identifiers with consistent counts.
- HEX Core serves the catalog's Product System, LCI Dataset, and Integrated LCA schemas.

These are deployment-readiness checks, not an environmental calculation or numerical benchmark. Combined-service targets also run the existing RE Indicators compute check. Full calculation tests are maintained with the SEE service.

Production Kubernetes validation checks service readiness without authenticated core requests by default. Set `SEE_IMPACTS_HEX_CORE_BEARER_TOKEN` in the validator's shell environment to also check the three schemas against an authenticated core. That variable authenticates the validator only; configuring the running SEE service still requires the Kubernetes Secret. A reachable identity provider and valid core authentication settings are required for those requests to succeed.

The validation helper itself has lightweight tests that do not require containers, a cluster, or network access:

```bash
make validate-helpers
```

## Failure domains

Common deployment failures are likely to come from:

- invalid auth configuration
- unreachable or misconfigured `io-adapter`
- registry catalog mismatch or invalid artifact URLs
- blocked network egress
- image tag drift
- insufficient writable workspace or resources for SEE calculations
- a missing or expired SEE bearer token when core authentication is enabled

Production-oriented overlays may also appear healthy while still rejecting unauthenticated smoke traffic by design.
