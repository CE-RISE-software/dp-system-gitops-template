# CE-RISE DP System GitOps Template

This documentation describes how to use this repository as a deployment template for a CE-RISE Digital Passport system instance.

The template deploys `hex-core-service` as the stable application component and treats the HTTP `io-adapter` as a replaceable integration boundary.
The default baseline is Docker Compose. The production target includes Kubernetes manifests based on Kustomize.

What this template assumes:

- `hex-core-service` is the public-facing application component.
- The `io-adapter` is an internal trusted service unless an adopter explicitly chooses a different exposure model.
- Registry configuration is a first-class deployment concern.
- Outbound network access from `hex-core-service` to the configured registry source and `io-adapter` is required.
- The template uses pinned image references and pinned model catalog entries in release-ready examples.
- Optional downstream services may be layered on top through isolated Compose profiles or Kustomize overlays.

Use the sections in this documentation according to your deployment task. They are designed as peer references rather than a single linear tutorial.

---

Funded by the European Union under Grant Agreement No. 101092281 — CE-RISE.  
Views and opinions expressed are those of the author(s) only and do not necessarily reflect those of the European Union or the granting authority (HADEA).
Neither the European Union nor the granting authority can be held responsible for them.

<a href="https://ce-rise.eu/" target="_blank" rel="noopener noreferrer">
  <img src="images/CE-RISE_logo.png" alt="CE-RISE logo" width="200"/>
</a>
