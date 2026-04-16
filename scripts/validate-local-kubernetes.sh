#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
overlay_name="${K8S_OVERLAY:-dev}"
overlay_dir="$repo_root/k8s/overlays/$overlay_name"
namespace="dp-system-dev"
port_forward_pid=""
calc_port_forward_pid=""
sample_re_indicators_payload="/tmp/k8s-re-indicators-sample-payload.json"
skip_authenticated_checks=false

case "$overlay_name" in
  dev|dev-re-indicators)
    namespace="dp-system-dev"
    ;;
  prod|prod-re-indicators)
    namespace="dp-system-prod"
    skip_authenticated_checks=true
    ;;
  *)
    echo "Unsupported K8S_OVERLAY=$overlay_name" >&2
    exit 1
    ;;
esac

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

wait_for_namespace_absent() {
  local ns="$1"
  local timeout="$2"
  local started
  started="$(date +%s)"

  while true; do
    if ! kubectl get namespace "$ns" >/dev/null 2>&1; then
      return 0
    fi
    if (( "$(date +%s)" - started >= timeout )); then
      echo "Timed out waiting for namespace $ns to be deleted" >&2
      kubectl get namespace "$ns" -o yaml >&2 || true
      return 1
    fi
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
  if [[ "$overlay_name" == *"re-indicators"* ]]; then
    echo "re-indicators-calculation-service logs:" >&2
    kubectl logs -n "$namespace" deployment/re-indicators-calculation-service >&2 || true
  fi
}

cleanup() {
  if [[ -n "$port_forward_pid" ]]; then
    kill "$port_forward_pid" >/dev/null 2>&1 || true
    wait "$port_forward_pid" >/dev/null 2>&1 || true
  fi
  if [[ -n "$calc_port_forward_pid" ]]; then
    kill "$calc_port_forward_pid" >/dev/null 2>&1 || true
    wait "$calc_port_forward_pid" >/dev/null 2>&1 || true
  fi
  kubectl delete -k "$overlay_dir" >/dev/null 2>&1 || true
  wait_for_namespace_absent "$namespace" 120 || true
  rm -f "$sample_re_indicators_payload"
}

validate_rendered_catalog_shape() {
  local rendered
  rendered="$(kubectl kustomize "$overlay_dir")"
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

write_re_indicators_payload() {
  cat >"$sample_re_indicators_payload" <<'EOF'
{
  "model_version": "0.0.5",
  "payload": {
    "id": "template-k8s-re-indicators-reuse-001",
    "timestamp": "2026-04-15T12:00:00Z",
    "model_version": "0.0.5",
    "indicator_specification_id": "REuse_Laptop",
    "product_info": {
      "product_category": "Laptop",
      "manufacturer": "Leveto",
      "model": "T14 Eco",
      "serial_number": "LVT-T14E-001"
    },
    "parameter_assessments": [
      {
        "parameter_id": "P1_product_diagnosis",
        "question_answers": [
          {
            "question_id": "Q1.1",
            "selected_answer_id": "product_id_all_key_info"
          },
          {
            "question_id": "Q1.2",
            "selected_answer_id": "core_func_easy"
          },
          {
            "question_id": "Q1.3",
            "selected_answer_id": "wear_tear_somewhat_easy"
          }
        ]
      },
      {
        "parameter_id": "P2_warranty_information",
        "question_answers": [
          {
            "question_id": "Q2.1",
            "selected_answer_id": "warranty_clearly_indicated"
          }
        ]
      },
      {
        "parameter_id": "P3_resetting_product",
        "question_answers": [
          {
            "question_id": "Q3.1",
            "selected_answer_id": "physical_reset_follow_manual"
          },
          {
            "question_id": "Q3.2",
            "selected_answer_id": "software_reset_very_easy"
          }
        ]
      },
      {
        "parameter_id": "P4_data_confidentiality",
        "question_answers": [
          {
            "question_id": "Q4.1",
            "selected_answer_id": "data_deletion_secure_easy"
          }
        ]
      },
      {
        "parameter_id": "P5_new_ownership",
        "question_answers": [
          {
            "question_id": "Q5.1",
            "selected_answer_id": "ownership_transfer_partial"
          }
        ]
      }
    ]
  }
}
EOF
}

run_re_indicators_compute_check() {
  local status=""

  write_re_indicators_payload
  status="$(curl -sS -o /tmp/k8s-re-indicators-compute-response.json -w '%{http_code}' \
    -X POST "http://127.0.0.1:18081/compute" \
    -H "Content-Type: application/json" \
    --data-binary @"$sample_re_indicators_payload")"

  if [[ "$status" != "200" ]]; then
    echo "RE indicators compute request failed with HTTP $status" >&2
    cat /tmp/k8s-re-indicators-compute-response.json >&2 || true
    return 1
  fi

  python3 - <<'PY' /tmp/k8s-re-indicators-compute-response.json
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    response = json.load(fh)

if "result" not in response:
    raise SystemExit("compute response did not include 'result'")
if "total_score" not in response["result"]:
    raise SystemExit("compute response did not include 'result.total_score'")
PY
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

if [[ -d "$repo_root/k8s/overlays/dev-re-indicators" ]]; then
  echo "Validating Kustomize dev-re-indicators overlay rendering"
  kubectl kustomize "$repo_root/k8s/overlays/dev-re-indicators" >/dev/null
fi

if [[ -d "$repo_root/k8s/overlays/prod-re-indicators" ]]; then
  echo "Validating Kustomize prod-re-indicators overlay rendering"
  kubectl kustomize "$repo_root/k8s/overlays/prod-re-indicators" >/dev/null
fi

echo "Validating rendered Kubernetes catalog shape"
validate_rendered_catalog_shape

if kubectl get namespace "$namespace" >/dev/null 2>&1; then
  echo "Waiting for previous $namespace deletion"
  kubectl delete namespace "$namespace" >/dev/null 2>&1 || true
  wait_for_namespace_absent "$namespace" 120
fi

echo "Applying Kubernetes $overlay_name overlay"
kubectl apply -k "$overlay_dir" >/dev/null

echo "Waiting for hex-core-service rollout"
kubectl rollout status deployment/hex-core-service -n "$namespace" --timeout=180s

if [[ "$overlay_name" == *"re-indicators"* ]]; then
  echo "Waiting for re-indicators-calculation-service rollout"
  kubectl rollout status deployment/re-indicators-calculation-service -n "$namespace" --timeout=180s
fi

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

if [[ "$skip_authenticated_checks" == "true" ]]; then
  echo "Skipping authenticated core smoke checks for $overlay_name"
else
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
fi

if [[ "$overlay_name" == *"re-indicators"* ]]; then
  echo "Port-forwarding re-indicators-calculation-service"
  kubectl port-forward -n "$namespace" service/re-indicators-calculation-service 18081:8081 >/tmp/dp-k8s-re-indicators-port-forward.log 2>&1 &
  calc_port_forward_pid="$!"
  sleep 3

  echo "Waiting for Kubernetes RE indicators health endpoint"
  if ! wait_for_http_code "http://127.0.0.1:18081/health" "200" "90"; then
    echo "Kubernetes RE indicators health check failed" >&2
    k8s_logs_on_failure
    exit 1
  fi

  if [[ "$skip_authenticated_checks" == "true" ]]; then
    echo "Skipping authenticated RE indicators compute check for $overlay_name"
  else
    echo "Checking Kubernetes RE indicators compute flow"
    if ! run_re_indicators_compute_check; then
      k8s_logs_on_failure
      exit 1
    fi
  fi
fi

echo "Kubernetes smoke test completed"
