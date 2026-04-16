# Optional Extensions

This template may be expanded with optional downstream services without changing the baseline deployment contract between `hex-core-service` and the configured `io-adapter`.

## RE indicators calculation service

The Compose template includes an optional `re-indicators` profile that adds `re-indicators-calculation-service`.

This service:

- depends on `hex-core-service`
- validates RE indicators payloads through the core service
- resolves its own published RE indicators artifacts
- does not talk to the `io-adapter` directly as part of the template contract

Relevant configuration in [`compose/.env.example`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/compose/.env.example):

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

The optional calculation service should remain isolated from the baseline template path. Operators who do not need it should be able to ignore it completely.

## Kubernetes shape

The Kubernetes side is modeled as an isolated extension and overlay path:

- [`k8s/extensions/re-indicators`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/k8s/extensions/re-indicators)
- [`k8s/overlays/dev-re-indicators`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/k8s/overlays/dev-re-indicators)
- [`k8s/overlays/prod-re-indicators`](/home/riccardo/code/CE-RISE-software/dp-system-gitops-template/k8s/overlays/prod-re-indicators)

This keeps `dev` and `prod` as clean baseline overlays while allowing explicit opt-in composition for the calculation service.

The `dev-re-indicators` overlay has been runtime-validated locally.
The `prod-re-indicators` overlay is deployment- and health-validated locally, but its authenticated functional smoke checks remain dependent on real production auth wiring.
