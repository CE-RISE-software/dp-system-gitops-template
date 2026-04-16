# Kubernetes

This directory contains the production-template Kubernetes scaffolding based on Kustomize.

The baseline assumptions match the Compose template:

- `hex-core-service` is the public-facing component
- the default `io-adapter` is external
- registry configuration is mounted from a local catalog file representation
- secrets are modeled explicitly and can be replaced by the adopter's preferred secret solution

Optional extension overlays are also included:

- `overlays/dev-re-indicators`
- `overlays/prod-re-indicators`

These compose the baseline overlays with the isolated `extensions/re-indicators` resources so the optional calculation service does not leak into the baseline Kubernetes path.
