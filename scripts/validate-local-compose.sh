#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose_dir="$repo_root/compose"
compose_env="$compose_dir/.env"
compose_profiles="${COMPOSE_PROFILES:-}"
sample_re_indicators_payload="/tmp/re-indicators-sample-payload.json"

# This local smoke test depends on working external DNS from inside the
# rootless Podman container. On this workstation that required switching
# Podman rootless networking to slirp4netns and resetting Podman state.
run_compose() {
  local args=()
  local profile=""

  if [[ -n "$compose_profiles" ]]; then
    IFS=',' read -r -a args <<<"$compose_profiles"
    local expanded=()
    for profile in "${args[@]}"; do
      [[ -n "$profile" ]] || continue
      expanded+=(--profile "$profile")
    done
    (
      cd "$compose_dir"
      docker compose "${expanded[@]}" "$@"
    )
    return
  fi

  (
    cd "$compose_dir"
    docker compose "$@"
  )
}

cleanup() {
  run_compose down --remove-orphans >/dev/null 2>&1 || true
  if command -v podman >/dev/null 2>&1; then
    podman rm -f compose_hex-core-service_1 >/dev/null 2>&1 || true
    podman rm -f compose_re-indicators-calculation-service_1 >/dev/null 2>&1 || true
    podman network rm -f compose_default >/dev/null 2>&1 || true
  fi
  rm -f "$sample_re_indicators_payload"
}

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

compose_logs_on_failure() {
  echo "Docker Compose service status:" >&2
  run_compose ps >&2 || true
  echo "hex-core-service logs:" >&2
  run_compose logs hex-core-service >&2 || true
  if [[ ",$compose_profiles," == *",re-indicators,"* ]]; then
    echo "re-indicators-calculation-service logs:" >&2
    run_compose logs re-indicators-calculation-service >&2 || true
  fi
}

compose_up_services() {
  local services=("hex-core-service")

  if [[ ",$compose_profiles," == *",re-indicators,"* ]]; then
    services+=("re-indicators-calculation-service")
  fi

  run_compose up -d "${services[@]}" >/dev/null
}

write_re_indicators_payload() {
  cat >"$sample_re_indicators_payload" <<'EOF'
{
  "model_version": "0.0.5",
  "payload": {
    "id": "template-re-indicators-reuse-001",
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
  status="$(curl -sS -o /tmp/re-indicators-compute-response.json -w '%{http_code}' \
    -X POST "http://127.0.0.1:8083/compute" \
    -H "Content-Type: application/json" \
    --data-binary @"$sample_re_indicators_payload")"

  if [[ "$status" != "200" ]]; then
    echo "RE indicators compute request failed with HTTP $status" >&2
    cat /tmp/re-indicators-compute-response.json >&2 || true
    return 1
  fi

  python3 - <<'PY' /tmp/re-indicators-compute-response.json
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

validate_catalog_shape() {
  python3 - <<'PY' "$compose_dir/registry/catalog.json"
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    catalog = json.load(fh)

entries = catalog.get("models", [])
if not isinstance(entries, list) or not entries:
    raise SystemExit("catalog.json must contain a non-empty 'models' array")

artifact_keys = {"route_url", "schema_url", "shacl_url", "owl_url", "openapi_url"}
for index, entry in enumerate(entries, start=1):
    if "base_url" in entry:
        raise SystemExit(f"catalog entry {index} still uses deprecated 'base_url'")
    if not any(entry.get(key) for key in artifact_keys):
        raise SystemExit(
            f"catalog entry {index} must declare at least one explicit artifact URL"
        )
PY
}

echo "Preparing local Compose environment"
cp "$compose_dir/.env.example" "$compose_env"
cat >>"$compose_env" <<'EOF'
AUTH_MODE=none
AUTH_ALLOW_INSECURE_NONE=true
EOF

trap cleanup EXIT

echo "Cleaning any previous local Compose stack"
cleanup

echo "Validating local catalog shape"
validate_catalog_shape

echo "Validating Docker Compose rendering"
run_compose config >/dev/null

echo "Running Docker Compose smoke test"
compose_up_services

echo "Waiting for Docker Compose health endpoint"
if ! wait_for_http_code "http://127.0.0.1:8080/admin/health" "200" "90"; then
  echo "Docker Compose health check failed" >&2
  compose_logs_on_failure
  exit 1
fi

echo "Waiting for Docker Compose readiness endpoint"
if ! wait_for_http_code "http://127.0.0.1:8080/admin/ready" "200" "90"; then
  echo "Docker Compose readiness check failed" >&2
  compose_logs_on_failure
  exit 1
fi

echo "Checking Docker Compose model listing"
if ! wait_for_http_code "http://127.0.0.1:8080/models" "200" "30"; then
  echo "Docker Compose model listing failed" >&2
  compose_logs_on_failure
  exit 1
fi

if [[ ",$compose_profiles," == *",re-indicators,"* ]]; then
  echo "Waiting for RE indicators calculation service health endpoint"
  if ! wait_for_http_code "http://127.0.0.1:8083/health" "200" "90"; then
    echo "RE indicators calculation service health check failed" >&2
    compose_logs_on_failure
    exit 1
  fi

  echo "Checking sample RE indicators compute flow"
  if ! run_re_indicators_compute_check; then
    compose_logs_on_failure
    exit 1
  fi
fi

echo "Docker Compose smoke test completed"
