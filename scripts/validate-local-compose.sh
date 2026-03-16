#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose_dir="$repo_root/compose"
compose_env="$compose_dir/.env"

# This local smoke test depends on working external DNS from inside the
# rootless Podman container. On this workstation that required switching
# Podman rootless networking to slirp4netns and resetting Podman state.
cleanup() {
  (
    cd "$compose_dir"
    docker compose down --remove-orphans >/dev/null 2>&1 || true
  )
  if command -v podman >/dev/null 2>&1; then
    podman rm -f compose_hex-core-service_1 >/dev/null 2>&1 || true
    podman network rm -f compose_default >/dev/null 2>&1 || true
  fi
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
  (
    cd "$compose_dir"
    echo "Docker Compose service status:" >&2
    docker compose ps >&2 || true
    echo "hex-core-service logs:" >&2
    docker compose logs hex-core-service >&2 || true
  )
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
(
  cd "$compose_dir"
  docker compose config >/dev/null
)

echo "Running Docker Compose smoke test"
(
  cd "$compose_dir"
  docker compose up -d hex-core-service >/dev/null
)

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

echo "Docker Compose smoke test completed"
