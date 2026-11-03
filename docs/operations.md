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

To inspect the baseline deployment, run from `compose/`:

```bash
docker compose ps
docker compose logs hex-core-service
curl --fail http://localhost:8080/admin/health
```

For deployments with both application services:

```bash
docker compose --profile re-indicators --profile see-impacts ps
docker compose --profile re-indicators --profile see-impacts logs re-indicators-calculation-service see-impacts-calculation-service
curl --fail http://localhost:8083/health
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

To inspect an existing development deployment:

```bash
kubectl get pods -n dp-system-dev
kubectl logs -n dp-system-dev deployment/hex-core-service
```

When the corresponding application services are enabled:

```bash
kubectl logs -n dp-system-dev deployment/re-indicators-calculation-service
kubectl logs -n dp-system-dev deployment/see-impacts-calculation-service
kubectl port-forward -n dp-system-dev service/see-impacts-calculation-service 18084:8080
```

With the port forward running, the SEE endpoints are available at `http://localhost:18084`.

## Validation Coverage

The baseline checks render the deployment configuration, start HEX Core, and check health. Development validation also checks core readiness and model listing. Production authentication requirements are described below.

Application-service checks add:

| Service | Checks |
| --- | --- |
| RE Indicators | `/health`; development validation also sends a `POST /compute` smoke request through its core connection |
| SEE Impacts | `/health`, `/capabilities`, and `/methods` initialization responses; required schemas available through HEX Core |

The SEE validator checks service identity, initialization metadata, non-empty and consistent method registration, and the schema versions in the supplied catalog. Combined targets run both sets of application-service checks.

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
- insufficient writable working storage or service resources
- a missing or expired SEE bearer token when core authentication is enabled

Production-oriented overlays may also appear healthy while still rejecting unauthenticated smoke traffic by design.
