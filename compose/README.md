# Compose Baseline

This directory contains the baseline Docker Compose deployment template.

Default mode:

- deploy `hex-core-service`
- mount a pinned local registry catalog with explicit artifact URLs
- point the core service to an external HTTP `io-adapter`

Optional profiles:

- enable the `internal-adapter` profile to add an adapter service slot to the stack
- enable the `re-indicators` profile to add `re-indicators-calculation-service` beside `hex-core-service`
- enable the `see-impacts` profile to add `see-impacts-calculation-service` at `127.0.0.1:8084`

Copy `.env.example` to `.env` if no deployment configuration exists yet, then set the adapter endpoint and authentication settings for your environment. From this directory:

```bash
docker compose --profile see-impacts up -d
```

Image defaults in `.env.example` use explicit release tags. Existing `.env` files are not changed automatically; update their image variables to adopt the [supplied versions](https://ce-rise-software.codeberg.page/dp-system-gitops-template/configuration.html#images).

To run both calculation services:

```bash
docker compose --profile re-indicators --profile see-impacts up -d
```

The SEE image contains the BONSAI background and EF 3.1 methods. Its request workspaces are temporary; no background-data mount or persistent volume is required. Configure `SEE_IMPACTS_HEX_CORE_BEARER_TOKEN` when HEX Core requires a bearer token. Keep credentials out of version control.

SEE is published on the host's loopback interface only; other containers can reach it on the Compose network. For remote access, use an authenticated reverse proxy. The HEX Core token authenticates SEE's outgoing validation requests, not incoming requests to SEE.

See the [extension documentation](https://ce-rise-software.codeberg.page/dp-system-gitops-template/extensions.html) for configuration and validation commands. Without these profiles, the baseline remains unchanged.
