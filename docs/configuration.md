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

## Optional downstream services

The baseline template does not require any downstream application service beside `hex-core-service`.

If the optional `re-indicators` Compose profile is enabled, the following variables are also used:

- `RE_INDICATORS_CALC_IMAGE`
- `RE_INDICATORS_CALC_PORT`
- `RE_INDICATORS_HEX_CORE_BASE_URL`
- `RE_INDICATORS_ARTIFACT_BASE_URL_TEMPLATE`
- `RE_INDICATORS_HTTP_TIMEOUT_SECS`

## Images

- Use explicit image references with immutable version tags.
- Do not use `latest` in release-ready examples.
- Update pinned image tags as part of template releases.
