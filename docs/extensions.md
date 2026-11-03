# Optional Extensions

Optional application services are enabled through Compose profiles or Kustomize overlays. They connect to `hex-core-service` without changing the baseline core-to-adapter deployment contract. Container versions are listed in [Configuration](configuration.md#images).

## RE indicators calculation service

The Compose template includes an optional `re-indicators` profile that adds `re-indicators-calculation-service`.

It connects to HEX Core over the Compose network and publishes container port `8081` on host port `8083` by default. Configure its image, host port, core endpoint, artifact endpoint, and HTTP timeout using the [RE Indicators settings](configuration.md#re-indicators).

Typical local commands:

```bash
cd compose
docker compose --profile re-indicators up -d
cd ..
COMPOSE_PROFILES=re-indicators ./scripts/validate-local-compose.sh
K8S_OVERLAY=dev-re-indicators ./scripts/validate-local-kubernetes.sh
```

The service is deployed only when its profile or overlay is selected.

## SEE impacts calculation service

The `see-impacts` profile adds `see-impacts-calculation-service`. It connects to HEX Core over the Compose network and publishes container port `8080` at `127.0.0.1:8084` by default. Configure its image, host port, core endpoint, credentials, timeouts, and concurrency using the [SEE settings](configuration.md#see-impacts).

From the repository root, after configuring `compose/.env`:

```bash
cd compose
docker compose --profile see-impacts up -d
curl --fail http://localhost:8084/capabilities
```

Other containers can reach SEE on the Compose network. Remote access requires an authenticated reverse proxy; the HEX Core bearer token does not authenticate incoming SEE requests. The Compose health check uses `/capabilities` to verify service initialization. Writable working storage is provided by the container's writable layer; no persistent volume is required.

Set `SEE_IMPACTS_HEX_CORE_BEARER_TOKEN` when HEX Core requires authentication. Keep credentials out of version control.

## Kubernetes overlays

| Services | Development overlay | Production overlay |
| --- | --- | --- |
| RE Indicators | `dev-re-indicators` | `prod-re-indicators` |
| SEE Impacts | `dev-see-impacts` | `prod-see-impacts` |
| Both | `dev-calculations` | `prod-calculations` |

Each overlay combines the appropriate baseline with resources under `k8s/extensions/`. The combined overlays include the core only once. The baseline `dev` and `prod` overlays remain independent of both calculation services.

Both extensions provide ClusterIP services and ConfigMaps:

| Extension | Service Port | ConfigMap | Pod Probes |
| --- | --- | --- | --- |
| RE Indicators | `8081` | `re-indicators-env` | No pod probes configured |
| SEE Impacts | `8080` | `see-impacts-env` | Startup and liveness: `/health`; readiness: `/capabilities` |

SEE mounts an `emptyDir` at `/var/lib/see-impacts/brightway` for temporary working storage. The deployment requests one CPU and 2 GiB of memory. Adjust resources, concurrency, and temporary disk space for the expected workload. The RE Indicators extension does not set resource requests or mount working volumes.

The `see-impacts-env` ConfigMap supplies the core URL, timeouts, concurrency, and workspace path. For authenticated deployments, create a `see-impacts-auth` Secret in the selected namespace with a `HEX_CORE_BEARER_TOKEN` key. Manage this secret through your deployment's secret-management mechanism, not a committed token.

## Running both services

Compose:

```bash
cd compose
docker compose --profile re-indicators --profile see-impacts up -d
```

Kubernetes, from the repository root:

```bash
kubectl apply -k k8s/overlays/dev-calculations
```

For production, configure the core authentication and adapter settings, supply the SEE token, and use `prod-calculations` instead. Production overlays do not configure an identity provider for you.

## Deployment validation

From the repository root:

```bash
make validate-compose-see-impacts
make validate-compose-calculations
make validate-kubernetes-see-impacts
make validate-kubernetes-calculations
```

These checks verify deployment rendering, service startup, initialization responses, and required schema availability through HEX Core. The RE Indicators and combined targets also perform an API smoke request. See [Operations](operations.md) for exact coverage, test isolation, and production authentication requirements.

## Component Documentation

Use the component documentation for API usage and service-specific behavior:

- [RE Indicators documentation](https://ce-rise-software.codeberg.page/re-indicators-calculation-service/)
- [SEE Impacts documentation](https://ce-rise-software.codeberg.page/see-impacts-calculation-service/)
