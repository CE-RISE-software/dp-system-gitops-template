# Deployment

The template supports Docker Compose and Kubernetes with Kustomize. Both use the same model catalog and default to an external HTTP IO adapter.

## Docker Compose

- Docker Compose is the mandatory working baseline.
- The default deployment points `hex-core-service` at an external HTTP `io-adapter`.
- The default registry source is a local pinned catalog file mounted into the container.
- The catalog uses explicit per-artifact URLs for each model entry.

Configuration lives in `compose/docker-compose.yml`, `compose/.env.example`, and `compose/registry/catalog.json`.

From the repository root, create `compose/.env` from `compose/.env.example` if it does not already exist. Configure the adapter endpoint and authentication before starting services:

```bash
cd compose
docker compose config
docker compose up -d
```

Add SEE with its optional profile:

```bash
docker compose --profile see-impacts up -d
```

Or run both calculation services alongside the same core:

```bash
docker compose --profile re-indicators --profile see-impacts up -d
```

The default host ports are `8080` for HEX Core, `8083` for RE Indicators, and `8084` for SEE Impacts. SEE is bound to `127.0.0.1`, so its published port is accessible only from the deployment host. Other containers reach it through the Compose network. Use the corresponding port variables in `.env` to change the port numbers. When inspecting or stopping optional services, select the same profiles.

For remote SEE access, configure an authenticated reverse proxy. The service's HEX Core bearer token protects its outgoing validation requests, not incoming requests to the calculation API.

## Kubernetes

- Kubernetes manifests are included using Kustomize.
- Secret handling is part of the production template path.
- Operators may replace plain secret manifests with Sealed Secrets, SOPS, or external secret managers.

The baseline resources are in `k8s/base`, with environment configuration in `k8s/overlays/dev` and `k8s/overlays/prod`. Render the selected overlay before applying it. From the repository root, for SEE in a development namespace:

```bash
kubectl kustomize k8s/overlays/dev-see-impacts
kubectl apply -k k8s/overlays/dev-see-impacts
```

Use `dev-calculations` for both services. The corresponding production overlays are `prod-see-impacts` and `prod-calculations`; configure their auth and adapter settings before applying them. All SEE services are cluster-internal by default. Configure an authenticated ingress or reverse proxy separately if external access is needed.

## Adapter deployment modes

- External adapter: default and documented baseline.
- Internal adapter slot: supported as an optional extension point, not as the default template path.

## Optional downstream services

The template may also host optional services that sit beside `hex-core-service` and use it as an application dependency.

- RE Indicators Calculation and SEE Impacts Calculation have separate Compose profiles and Kubernetes extensions.
- Both depend on `hex-core-service` for model validation, not directly on the IO adapter.
- Their required models are registered in the supplied versioned catalogs.
- Both can be deployed together without duplicating the core resources.

SEE includes its BONSAI background and EF 3.1 factors in the released image. Every calculation uses an isolated temporary Brightway project. No background-data mount, caller-supplied Brightway project, or persistent volume is required. Kubernetes uses an `emptyDir` workspace and requests one CPU and 2 GiB of memory for SEE. Allow sufficient temporary disk space for concurrent background copies and adjust resources for your assessments.

When core authentication is enabled, configure the SEE bearer token using the Compose variable or Kubernetes Secret described in [Configuration](configuration.md). See [Optional Extensions](extensions.md) for all service combinations.

## Development overlay

The development overlay supplies:

- dedicated namespace
- debug logging
- example cluster-local adapter URL override
- insecure auth mode for development only

This overlay is not the production security model. It exists to make local and early-cluster testing easier.

## Production overlay

The production overlay supplies:

- dedicated production namespace
- `jwt_jwks` authentication path
- example auth secret manifest
- replica count and resource requests/limits

This overlay is still a template starting point. Operators are expected to replace example secret material and environment-specific endpoints.

## Network assumptions

- `hex-core-service` must be able to reach the configured `io-adapter`.
- `hex-core-service` must be able to fetch model artifacts from the configured registry sources.
- Calculation services must be able to reach `hex-core-service` using their configured service URL.
- Reverse proxies serving SEE requests must allow sufficient response time for calculations; the worker time limit defaults to 900 seconds.
