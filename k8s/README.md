# Kubernetes

This directory contains the production-template Kubernetes scaffolding based on Kustomize.

The baseline assumptions match the Compose template:

- `hex-core-service` is the public-facing component
- the default `io-adapter` is external
- registry configuration is mounted from a local catalog file representation
- secrets are modeled explicitly and can be replaced by the adopter's preferred secret solution
