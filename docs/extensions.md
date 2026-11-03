# Optional Extensions

This template may be expanded with optional downstream services without changing the baseline deployment contract between `hex-core-service` and the configured `io-adapter`.

## RE indicators calculation service

The Compose template includes an optional `re-indicators` profile that adds `re-indicators-calculation-service`.

This service:

- depends on `hex-core-service`
- validates RE indicators payloads through the core service
- resolves its own published RE indicators artifacts
- does not talk to the `io-adapter` directly as part of the template contract

Relevant configuration in `compose/.env.example`:

- `RE_INDICATORS_CALC_IMAGE`
- `RE_INDICATORS_CALC_PORT`
- `RE_INDICATORS_HEX_CORE_BASE_URL`
- `RE_INDICATORS_ARTIFACT_BASE_URL_TEMPLATE`
- `RE_INDICATORS_HTTP_TIMEOUT_SECS`

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

The `see-impacts` profile adds `see-impacts-calculation-service` using `rg.fr-par.scw.cloud/ce-rise-software/see-impacts-calculation:v0.0.1`. The image includes the BONSAI background and fixed Environmental Footprint (EF) 3.1 characterization factors. Each request supplies its own foreground records and functional unit; no product-specific Brightway project is required from the caller.

The service uses HEX Core to validate Product System and LCI Dataset inputs and its Integrated LCA output. A successful request returns all 25 configured impact indicators in one result record. See the [SEE service documentation](https://ce-rise-software.codeberg.page/see-impacts-calculation-service/) for request fields, background references, and result structure.

From the repository root, after configuring `compose/.env`:

```bash
cd compose
docker compose --profile see-impacts up -d
curl --fail http://localhost:8084/capabilities
```

SEE listens on container port `8080`, published at `127.0.0.1:8084` by default. Other containers can reach it on the Compose network. Remote access requires an authenticated reverse proxy; the HEX Core bearer token does not authenticate incoming SEE requests. The Compose health check uses `/capabilities` to verify that the background can be opened. No background-data mount is needed. Request workspaces use writable temporary storage inside the container, not a required persistent volume.

Configuration is listed in [Configuration](configuration.md). Set `SEE_IMPACTS_HEX_CORE_BEARER_TOKEN` when HEX Core requires authentication. SEE does not use the IO adapter directly or save returned results through it.

## Kubernetes overlays

| Services | Development overlay | Production overlay |
| --- | --- | --- |
| RE Indicators | `dev-re-indicators` | `prod-re-indicators` |
| SEE Impacts | `dev-see-impacts` | `prod-see-impacts` |
| Both | `dev-calculations` | `prod-calculations` |

Each overlay combines the appropriate baseline with resources under `k8s/extensions/`. The combined overlays include the core only once. The baseline `dev` and `prod` overlays remain independent of both calculation services.

For SEE, the extension provides a ClusterIP service on port `8080`, startup and liveness checks at `/health`, and readiness at `/capabilities`. An `emptyDir` volume holds temporary Brightway workspaces. The deployment requests one CPU and 2 GiB of memory; adjust resources, concurrency, and available temporary disk space for the expected workload.

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

These checks verify service startup, access to the bundled BONSAI and EF 3.1 databases, method availability, and the three required schemas served by HEX Core. They do not run a full environmental assessment. The combined checks also run the existing RE Indicators calculation check. See [Operations](operations.md) for test isolation and production authentication requirements.
