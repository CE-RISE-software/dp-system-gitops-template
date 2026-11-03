#!/usr/bin/env python3
"""Check SEE readiness and the HEX Core schemas required for calculations."""

import argparse
import json
import os
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


REQUIRED_MODELS = ("product-system", "lci-dataset", "integrated-lca")


def get_json(url, token=None):
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    try:
        with urlopen(Request(url, headers=headers), timeout=30) as response:
            return json.load(response)
    except HTTPError as error:
        raise RuntimeError(f"{url} returned HTTP {error.code}") from error
    except (URLError, TimeoutError) as error:
        raise RuntimeError(f"Could not reach {url}") from error
    except (ValueError, UnicodeError) as error:
        raise RuntimeError(f"{url} did not return valid JSON") from error


def validate(service_url, catalog_path, hex_core_url=None, token=None):
    catalog = json.loads(Path(catalog_path).read_text(encoding="utf-8"))
    models = {entry["model"]: entry for entry in catalog["models"]}
    for model in REQUIRED_MODELS:
        if not models.get(model, {}).get("version"):
            raise RuntimeError(f"The catalog is missing a version for {model}")

    service_url = service_url.rstrip("/")
    health = get_json(service_url + "/health")
    if (
        not isinstance(health, dict)
        or health.get("service") != "see-impacts-calculation-service"
        or health.get("status") != "ok"
    ):
        raise RuntimeError("The SEE health endpoint did not identify a healthy calculator")
    capabilities = get_json(service_url + "/capabilities")
    if not isinstance(capabilities, dict) or not isinstance(
        capabilities.get("background"), dict
    ):
        raise RuntimeError("The SEE capabilities response is missing background metadata")
    background = capabilities.get("background", {})
    databases = {
        entry.get("name")
        for entry in background.get("databases", [])
        if isinstance(entry, dict)
    }
    if not {"BONSAI", "ef31_biosphere"}.issubset(databases):
        raise RuntimeError("The SEE background is missing BONSAI or EF3.1 elementary flows")
    methods = get_json(service_url + "/methods")
    if not isinstance(methods, dict):
        raise RuntimeError("The SEE methods response is not an object")
    identifiers = methods.get("methods", [])
    if not identifiers or not all(
        isinstance(method, list) and method and all(isinstance(part, str) for part in method)
        for method in identifiers
    ):
        raise RuntimeError("The SEE service did not report valid impact-method identifiers")
    if (
        methods.get("method_count") != len(identifiers)
        or background.get("method_count") != len(identifiers)
        or len({tuple(method) for method in identifiers}) != len(identifiers)
    ):
        raise RuntimeError("The SEE method counts or identifiers are inconsistent")
    print(f"SEE background ready: {len(identifiers)} impact methods available")

    if hex_core_url is None:
        print("HEX Core schema availability was not checked for this deployment")
        return
    for model in REQUIRED_MODELS:
        version = str(models[model]["version"])
        url = f"{hex_core_url.rstrip('/')}/models/{model}/versions/{quote(version, safe='')}/schema"
        schema = get_json(url, token=token)
        if not isinstance(schema, dict) or not any(
            key in schema for key in ("$schema", "$defs", "$ref", "type", "properties", "allOf")
        ):
            raise RuntimeError(f"HEX Core did not return a JSON Schema for {model} {version}")
        print(f"HEX Core schema available: {model} {version}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service-url", required=True)
    parser.add_argument("--catalog", required=True, type=Path)
    parser.add_argument("--hex-core-url")
    args = parser.parse_args()
    try:
        validate(
            args.service_url,
            args.catalog,
            args.hex_core_url,
            os.environ.get("SEE_IMPACTS_HEX_CORE_BEARER_TOKEN"),
        )
    except (RuntimeError, ValueError, KeyError, TypeError, OSError) as error:
        parser.exit(1, f"SEE validation failed: {error}\n")


if __name__ == "__main__":
    main()
