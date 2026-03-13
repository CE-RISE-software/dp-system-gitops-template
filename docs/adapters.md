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

The template may include an extension point for running an adapter service alongside `hex-core-service`.
That extension point must not become a hidden generic contract for all adapters.

## Adapter-specific concerns

These remain outside the generic template path:

- persistence layout
- backend storage technology
- proprietary system integration details
- adapter-specific auth beyond the core passthrough contract
