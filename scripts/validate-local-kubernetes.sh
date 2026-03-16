#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
namespace="dp-system-dev"
port_forward_pid=""

wait_for_http_code() {
  local url="$1"
  local expected="$2"
  local timeout="$3"
  local started
  local code=""
  local curl_stderr=""
  started="$(date +%s)"

  while true; do
    curl_stderr="$(mktemp)"
    code="$(curl -sS -o /tmp/dp-validator-body.json -w '%{http_code}' "$url" 2>"$curl_stderr" || true)"
    if [[ "$code" == "$expected" ]]; then
      rm -f "$curl_stderr"
      return 0
    fi
    if (( "$(date +%s)" - started >= timeout )); then
      echo "Timed out waiting for $url to return HTTP $expected; last HTTP $code" >&2
      if [[ -s "$curl_stderr" ]]; then
        cat "$curl_stderr" >&2
      fi
      if [[ -f /tmp/dp-validator-body.json ]]; then
        cat /tmp/dp-validator-body.json >&2
      fi
      rm -f "$curl_stderr"
      return 1
    fi
    rm -f "$curl_stderr"
    sleep 2
  done
}

k8s_logs_on_failure() {
  echo "Kubernetes resource status:" >&2
  kubectl get all -n "$namespace" >&2 || true
  echo "Kubernetes events:" >&2
  kubectl get events -n "$namespace" --sort-by=.lastTimestamp >&2 || true
  echo "hex-core-service logs:" >&2
  kubectl logs -n "$namespace" deployment/hex-core-service >&2 || true
}

cleanup() {
  if [[ -n "$port_forward_pid" ]]; then
    kill "$port_forward_pid" >/dev/null 2>&1 || true
    wait "$port_forward_pid" >/dev/null 2>&1 || true
  fi
  kubectl delete -k "$repo_root/k8s/overlays/dev" >/dev/null 2>&1 || true
}

validate_rendered_catalog_shape() {
  local rendered
  rendered="$(kubectl kustomize "$repo_root/k8s/overlays/dev")"
  if [[ "$rendered" != *"name: registry-catalog"* ]]; then
    echo "rendered kustomize output is missing registry-catalog ConfigMap" >&2
    return 1
  fi
  if [[ "$rendered" == *"base_url"* ]]; then
    echo "rendered registry catalog still uses deprecated base_url entries" >&2
    return 1
  fi
  if [[ "$rendered" != *"schema_url"* && "$rendered" != *"shacl_url"* && "$rendered" != *"route_url"* && "$rendered" != *"owl_url"* && "$rendered" != *"openapi_url"* ]]; then
    echo "rendered registry catalog does not declare any explicit artifact URLs" >&2
    return 1
  fi
}

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required for local Kubernetes validation" >&2
  exit 1
fi

trap cleanup EXIT

echo "Validating Kustomize base rendering"
kubectl kustomize "$repo_root/k8s/base" >/dev/null

echo "Validating Kustomize dev overlay rendering"
kubectl kustomize "$repo_root/k8s/overlays/dev" >/dev/null

echo "Validating Kustomize prod overlay rendering"
kubectl kustomize "$repo_root/k8s/overlays/prod" >/dev/null

echo "Validating rendered Kubernetes catalog shape"
validate_rendered_catalog_shape

echo "Applying Kubernetes dev overlay"
kubectl apply -k "$repo_root/k8s/overlays/dev" >/dev/null

echo "Waiting for hex-core-service rollout"
kubectl rollout status deployment/hex-core-service -n "$namespace" --timeout=180s

echo "Port-forwarding hex-core-service"
kubectl port-forward -n "$namespace" service/hex-core-service 18080:8080 >/tmp/dp-k8s-port-forward.log 2>&1 &
port_forward_pid="$!"
sleep 3

echo "Waiting for Kubernetes health endpoint"
if ! wait_for_http_code "http://127.0.0.1:18080/admin/health" "200" "90"; then
  echo "Kubernetes health check failed" >&2
  k8s_logs_on_failure
  exit 1
fi

echo "Waiting for Kubernetes readiness endpoint"
if ! wait_for_http_code "http://127.0.0.1:18080/admin/ready" "200" "90"; then
  echo "Kubernetes readiness check failed" >&2
  k8s_logs_on_failure
  exit 1
fi

echo "Checking Kubernetes model listing"
if ! wait_for_http_code "http://127.0.0.1:18080/models" "200" "30"; then
  echo "Kubernetes model listing failed" >&2
  k8s_logs_on_failure
  exit 1
fi

echo "Kubernetes smoke test completed"
