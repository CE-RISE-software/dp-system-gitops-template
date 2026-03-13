# Compose Baseline

This directory contains the baseline Docker Compose deployment template.

Default mode:

- deploy `hex-core-service`
- mount a pinned local registry catalog
- point the core service to an external HTTP `io-adapter`

Optional extension:

- enable the `internal-adapter` profile to add an adapter service slot to the stack

The optional adapter slot is not the primary template path and should be treated as an adopter extension point.
