# IO Adapters

This template treats the HTTP `io-adapter` as the pluggable backend boundary.

## Default expectation

- `hex-core-service` uses `IO_ADAPTER_ID=http`
- `IO_ADAPTER_BASE_URL` points at a trusted HTTP adapter service
- Bearer tokens are forwarded to the adapter when present

## Trust model

- The adapter is internal-only by default
- The adapter is a trusted backend component
- The adapter must not be exposed publicly by default

## External adapter mode

This is the normal template path.

- The template deploys `hex-core-service`
- The adapter is managed outside the baseline template stack
- The operator supplies `IO_ADAPTER_BASE_URL`

## Optional internal adapter slot

The `internal-adapter` Compose profile adds the `io-adapter` service alongside HEX Core. `IO_ADAPTER_IMAGE` selects its image. Add the environment settings, network access, and volumes required by the chosen adapter, then point `IO_ADAPTER_BASE_URL` to its internal HTTP endpoint.

This service slot does not supply an adapter-specific database configuration. Use the selected adapter's deployment documentation for its dependencies, credentials, and storage. No adapter Deployment is included in the Kubernetes baseline.

## Adapter-specific concerns

These remain outside the generic template path:

- persistence layout
- backend storage technology
- proprietary system integration details
- adapter-specific auth beyond the core passthrough contract
