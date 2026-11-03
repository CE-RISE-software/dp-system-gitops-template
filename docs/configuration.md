# Configuration

All runtime configuration is environment-driven.

The template keeps the `hex-core-service` variable names unchanged.

## Core runtime

Expected variables include:

- `SERVER_HOST`
- `SERVER_PORT`
- `LOG_LEVEL`
- `METRICS_ENABLED`

## IO adapter boundary

The template uses the current core contract directly:

- `IO_ADAPTER_ID`
- `IO_ADAPTER_BASE_URL`
- `IO_ADAPTER_TIMEOUT_MS`

Recommended baseline:

- `IO_ADAPTER_ID=http`
- `IO_ADAPTER_BASE_URL` points to an externally managed or separately deployed adapter

`memory` is a core development mode and is not part of the main deployment template path.

## Authentication

Default documented path:

- `AUTH_MODE=jwt_jwks`

Common variables:

- `AUTH_JWKS_URL`
- `AUTH_ISSUER`
- `AUTH_AUDIENCE`
- `AUTH_JWKS_REFRESH_SECS`

Alternative modes such as `forward_auth` are supported by the core but are deployment variants rather than the baseline.
`AUTH_MODE=none` is a dev-only escape hatch and should not be treated as a normal deployment mode.

Overlay intent:

- `k8s/overlays/dev` may use `AUTH_MODE=none` for local cluster bring-up
- `k8s/overlays/prod` uses the `jwt_jwks` path

## Registry

Registry configuration is a first-class deployment concern.

Recommended baseline:

- `REGISTRY_MODE=catalog`
- `REGISTRY_CATALOG_FILE=/config/registry/catalog.json`
- `REGISTRY_ALLOWED_HOSTS=codeberg.org`
- `REGISTRY_REQUIRE_HTTPS=true`

The template ships a pinned local catalog file with CE-RISE model entries.
Those entries use explicit artifact references such as `schema_url` and `shacl_url` rather than a single inferred `base_url`.

The Compose catalog (`compose/registry/catalog.json`) and Kubernetes catalog (`k8s/base/registry-configmap.yaml`) register these model versions:

| Model | Version |
| --- | --- |
| DP Record Metadata (`dp-record-metadata`) | `0.0.2` |
| Product Profile (`product-profile`) | `0.0.3` |
| Usage and Maintenance (`usage-and-maintenance`) | `0.0.2` |
| RE Indicators Specification (`re-indicators-specification`) | `0.0.5` |
| Product System (`product-system`) | `0.0.1` |
| LCI Dataset (`lci-dataset`) | `0.0.1` |
| Integrated LCA (`integrated-lca`) | `0.2.0` |

Schema and SHACL URLs point to the corresponding versioned `pages-v` tags on Codeberg. When updating registry configuration, keep the model identifiers, versions, and artifact URLs aligned in both catalogs. HEX Core needs outbound HTTPS access to the configured artifact hosts.

## Optional downstream services

The baseline template does not require any downstream application service beside `hex-core-service`.

### RE Indicators

The `re-indicators` Compose profile reads these settings from `compose/.env` or the shell environment:

| Variable | Default | Purpose |
| --- | --- | --- |
| `RE_INDICATORS_CALC_IMAGE` | `rg.fr-par.scw.cloud/ce-rise-software/re-indicators-calculation:v0.0.1` | Container image |
| `RE_INDICATORS_CALC_PORT` | `8083` | Host port mapped to container port `8081` |
| `RE_INDICATORS_HEX_CORE_BASE_URL` | `http://hex-core-service:8080` | Internal core endpoint |
| `RE_INDICATORS_ARTIFACT_BASE_URL_TEMPLATE` | `https://ce-rise-models.codeberg.page/re-indicators-specification/generated/` | Artifact endpoint reachable by the service |
| `RE_INDICATORS_HTTP_TIMEOUT_SECS` | `15` | Outgoing HTTP timeout in seconds |

Compose maps the connection settings to `HEX_CORE_BASE_URL`, `ARTIFACT_BASE_URL_TEMPLATE`, and `HTTP_TIMEOUT_SECS`. Kubernetes uses these native names in the `re-indicators-env` ConfigMap.

### SEE Impacts

The `see-impacts` Compose profile reads these settings from `compose/.env` or the shell environment:

| Variable | Default | Purpose |
| --- | --- | --- |
| `SEE_IMPACTS_CALC_IMAGE` | `rg.fr-par.scw.cloud/ce-rise-software/see-impacts-calculation:v0.0.1` | Container image |
| `SEE_IMPACTS_CALC_PORT` | `8084` | Loopback-only host port (`127.0.0.1`) mapped to container port `8080` |
| `SEE_IMPACTS_HEX_CORE_BASE_URL` | `http://hex-core-service:8080` | Internal core endpoint |
| `SEE_IMPACTS_HEX_CORE_BEARER_TOKEN` | Empty | Bearer token used for requests to HEX Core |
| `SEE_IMPACTS_HTTP_TIMEOUT_SECS` | `30` | Timeout for each HEX Core HTTP request |
| `SEE_IMPACTS_CALCULATION_TIMEOUT_SECS` | `900` | Calculation time limit in seconds |
| `SEE_IMPACTS_MAX_CONCURRENT_CALCULATIONS` | `2` | Calculation concurrency per service instance |

Compose maps the prefixed variables to the service's native variables: `HEX_CORE_BASE_URL`, `HEX_CORE_BEARER_TOKEN`, `HTTP_TIMEOUT_SECS`, `CALCULATION_TIMEOUT_SECS`, and `MAX_CONCURRENT_CALCULATIONS`.

The bearer token authenticates SEE's requests to HEX Core; it does not authenticate callers of SEE. Compose publishes SEE on `127.0.0.1` only, while Kubernetes uses a ClusterIP service. Provide an authenticated reverse proxy or ingress for remote access rather than exposing SEE directly.

Kubernetes uses those native names in the `see-impacts-env` ConfigMap and the optional `see-impacts-auth` Secret. Put `HEX_CORE_BEARER_TOKEN` in the Secret, not the ConfigMap. The prefixed Compose variables do not configure Kubernetes deployments.

Both deployments set `BRIGHTWAY_WORKSPACE_DIR=/var/lib/see-impacts/brightway`. This is writable temporary working storage, not record persistence. Kubernetes mounts an `emptyDir`; Compose uses the container's writable layer. Allow enough temporary disk space for the configured concurrency. No persistent volume is required by the supplied extension.

Keep `.env` files and token material out of version control. If requests pass through a reverse proxy, configure its response timeout to accommodate calculations up to the configured worker time limit.

## Images

The supplied image references select these published releases:

| Component | Container Image | Release |
| --- | --- | --- |
| HEX Core | `rg.fr-par.scw.cloud/ce-rise-software/hex-core-service:v0.0.9` | [v0.0.9](https://codeberg.org/CE-RISE-software/hex-core-service/releases/tag/v0.0.9) |
| RE Indicators Calculation | `rg.fr-par.scw.cloud/ce-rise-software/re-indicators-calculation:v0.0.1` | [v0.0.1](https://codeberg.org/CE-RISE-software/re-indicators-calculation-service/releases/tag/v0.0.1) |
| SEE Impacts Calculation | `rg.fr-par.scw.cloud/ce-rise-software/see-impacts-calculation:v0.0.1` | [v0.0.1](https://codeberg.org/CE-RISE-software/see-impacts-calculation-service/releases/tag/v0.0.1) |
| JSONDB, optional internal adapter | `rg.fr-par.scw.cloud/ce-rise-software/dp-storage-jsondb:v0.0.1` | [v0.0.1](https://codeberg.org/CE-RISE-software/dp-storage-jsondb-service/releases/tag/v0.0.1) |

Compose defines these defaults in `.env.example`; Kubernetes deployment manifests use the same versions. The JSONDB image belongs only to the optional Compose adapter slot, not the baseline or Kubernetes deployment.

Existing `compose/.env` files are not updated automatically. Set their image variables to the selected release tags when adopting this template version. Image overrides remain supported; use explicit release tags or digests rather than floating `latest` references, and keep Compose and Kubernetes references aligned.
