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
  echo "Validating Kustomize rendering"
  kubectl kustomize "$repo_root/k8s/base" >/dev/null
else
  echo "Skipping Kustomize rendering: kubectl not installed"
fi

echo "Local validation completed"
