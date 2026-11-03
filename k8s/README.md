# Kubernetes

This directory contains the production-template Kubernetes scaffolding based on Kustomize.

Deployment manifests use explicit release tags, aligned with the Compose defaults. The [configuration reference](https://ce-rise-software.codeberg.page/dp-system-gitops-template/configuration.html#images) lists the supplied versions.

The baseline assumptions match the Compose template:

- `hex-core-service` is the public-facing component
- the default `io-adapter` is external
- registry configuration is mounted from a local catalog file representation
- secrets are modeled explicitly and can be replaced by the adopter's preferred secret solution

Optional calculation-service overlays:

| Services | Development | Production |
| --- | --- | --- |
| RE Indicators | `overlays/dev-re-indicators` | `overlays/prod-re-indicators` |
| SEE Impacts | `overlays/dev-see-impacts` | `overlays/prod-see-impacts` |
| RE Indicators and SEE Impacts | `overlays/dev-calculations` | `overlays/prod-calculations` |

Each overlay includes the baseline once and adds the selected resources from `extensions/`. The `dev` and `prod` overlays do not deploy calculation services.

From the repository root:

```bash
kubectl kustomize k8s/overlays/dev-see-impacts
kubectl apply -k k8s/overlays/dev-see-impacts
```

SEE includes its background data in the image and uses an `emptyDir` workspace. It has a ClusterIP service on port `8080`, startup and liveness checks at `/health`, and a readiness check at `/capabilities`. The deployment requests one CPU and 2 GiB of memory; size resources and temporary disk space for your workloads.

For authenticated HEX Core deployments, supply a `see-impacts-auth` Secret containing `HEX_CORE_BEARER_TOKEN` in the selected namespace. Configure the production auth settings before deployment. See the [extension documentation](https://ce-rise-software.codeberg.page/dp-system-gitops-template/extensions.html).
