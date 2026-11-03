# CE-RISE DP System GitOps Template

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19050358.svg)](https://doi.org/10.5281/zenodo.19050358)

This repository provides a deployment template for a CE-RISE Digital Passport system instance.
It is centered on `hex-core-service` as the stable application component and a pluggable HTTP `io-adapter` as the storage and integration boundary.

The baseline deploys `hex-core-service` and connects it to an operator-selected HTTP IO adapter. Deployment configuration covers:

- Docker Compose and development/production Kubernetes overlays using Kustomize.
- Pinned container images and a local catalog of versioned model artifacts.
- Adapter endpoints, authentication, secrets, ports, and service configuration.
- Optional RE Indicators and SEE Impacts services, enabled separately or together.
- Local deployment checks, service readiness, logs, and resource configuration.

The default adapter is managed outside the stack. An optional Compose service slot supports an adapter in the same deployment without changing the core configuration contract.

Documentation:

- [Template documentation](https://ce-rise-software.codeberg.page/dp-system-gitops-template/)
- [Deployment](https://ce-rise-software.codeberg.page/dp-system-gitops-template/deployment.html)
- [Configuration](https://ce-rise-software.codeberg.page/dp-system-gitops-template/configuration.html)
- [Optional services](https://ce-rise-software.codeberg.page/dp-system-gitops-template/extensions.html)

## License

Licensed under the [European Union Public Licence v1.2 (EUPL-1.2)](LICENSE).

## Contributing

This repository is maintained on [Codeberg](https://codeberg.org/CE-RISE-software/dp-system-gitops-template) as the canonical source of truth. The GitHub repository is a read mirror used for release archival and Zenodo integration.

---

<a href="https://europa.eu" target="_blank" rel="noopener noreferrer">
  <img src="https://ce-rise.eu/wp-content/uploads/2023/01/EN-Funded-by-the-EU-PANTONE-e1663585234561-1-1.png" alt="EU emblem" width="200"/>
</a>

Funded by the European Union under Grant Agreement No. 101092281 — CE-RISE.  
Views and opinions expressed are those of the author(s) only and do not necessarily reflect those of the European Union or the granting authority (HADEA).
Neither the European Union nor the granting authority can be held responsible for them.

© 2026 CE-RISE consortium.  
Licensed under the [European Union Public Licence v1.2 (EUPL-1.2)](LICENSE).  
Attribution: CE-RISE project (Grant Agreement No. 101092281) and the individual authors/partners as indicated.

<a href="https://www.nilu.com" target="_blank" rel="noopener noreferrer">
  <img src="https://nilu.no/wp-content/uploads/2023/12/nilu-logo-seagreen-rgb-300px.png" alt="NILU logo" height="20"/>
</a>

Developed by NILU (Riccardo Boero — ribo@nilu.no) within the CE-RISE project.
