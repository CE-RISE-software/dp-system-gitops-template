# Compose Baseline

This directory contains the baseline Docker Compose deployment template.

Default mode:

- deploy `hex-core-service`
- mount a pinned local registry catalog with explicit artifact URLs
- point the core service to an external HTTP `io-adapter`

Optional extension:

- enable the `internal-adapter` profile to add an adapter service slot to the stack
- enable the `re-indicators` profile to add `re-indicators-calculation-service` beside `hex-core-service`

The optional services are not the primary template path and should be treated as adopter extension points.
