#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Preparing local Compose environment"
cp "$repo_root/compose/.env.example" "$repo_root/compose/.env"

echo "Validating Docker Compose rendering"
(
  cd "$repo_root/compose"
  docker compose config >/dev/null
)

if command -v kubectl >/dev/null 2>&1; then
  echo "Validating Kustomize base rendering"
  kubectl kustomize "$repo_root/k8s/base" >/dev/null
  echo "Validating Kustomize dev overlay rendering"
  kubectl kustomize "$repo_root/k8s/overlays/dev" >/dev/null
  echo "Validating Kustomize prod overlay rendering"
  kubectl kustomize "$repo_root/k8s/overlays/prod" >/dev/null
else
  echo "Skipping Kustomize rendering: kubectl not installed"
fi

echo "Local validation completed"
