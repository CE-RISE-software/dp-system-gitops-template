import contextlib
import copy
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import validate_see_service as checker


class SeeValidationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.catalog_path = Path(self.temporary.name) / "catalog.json"
        self.catalog = {"models": [
            {"model": model, "version": "0.2.0" if model == "integrated-lca" else "0.0.1"}
            for model in checker.REQUIRED_MODELS
        ]}
        self.catalog_path.write_text(json.dumps(self.catalog))
        self.replies = {
            "http://see/health": {"service": "see-impacts-calculation-service", "status": "ok"},
            "http://see/capabilities": {"background": {
                "databases": [{"name": "BONSAI"}, {"name": "ef31_biosphere"}],
                "method_count": 2,
            }},
            "http://see/methods": {"method_count": 2, "methods": [
                ["EF 3.1", "Climate change"], ["EF 3.1", "Water use"],
            ]},
        }
        for entry in self.catalog["models"]:
            self.replies[f"http://core/models/{entry['model']}/versions/{entry['version']}/schema"] = {
                "$schema": "https://json-schema.org/draft/2020-12/schema", "type": "object"
            }

    def validate(self, core="http://core", token=None):
        with patch.object(checker, "get_json", side_effect=lambda url, token=None: copy.deepcopy(self.replies[url])) as fetch:
            with contextlib.redirect_stdout(io.StringIO()) as output:
                checker.validate("http://see/", self.catalog_path, core, token)
        return fetch, output.getvalue()

    def test_healthy_service_and_catalog_schema_versions(self):
        fetch, output = self.validate(token="test-token")
        self.assertEqual(fetch.call_count, 6)
        self.assertIn("2 impact methods available", output)
        self.assertIn("integrated-lca 0.2.0", output)
        for call in fetch.call_args_list:
            if call.args[0].startswith("http://core/"):
                self.assertEqual(call.kwargs["token"], "test-token")
            else:
                self.assertNotIn("token", call.kwargs)

    def test_health_only_check_reports_schema_check_not_run(self):
        fetch, output = self.validate(core=None)
        self.assertEqual(fetch.call_count, 3)
        self.assertIn("schema availability was not checked", output)

    def test_missing_catalog_model_fails_before_http(self):
        self.catalog["models"].pop()
        self.catalog_path.write_text(json.dumps(self.catalog))
        with self.assertRaisesRegex(RuntimeError, "missing a version for integrated-lca"):
            self.validate()

    def test_wrong_service_is_rejected(self):
        self.replies["http://see/health"]["service"] = "another-service"
        with self.assertRaisesRegex(RuntimeError, "healthy calculator"):
            self.validate()

    def test_missing_background_is_rejected(self):
        self.replies["http://see/capabilities"]["background"]["databases"].pop()
        with self.assertRaisesRegex(RuntimeError, "missing BONSAI or EF3.1"):
            self.validate()

    def test_inconsistent_method_count_is_rejected(self):
        self.replies["http://see/methods"]["method_count"] = 3
        with self.assertRaisesRegex(RuntimeError, "inconsistent"):
            self.validate()

    def test_duplicate_methods_are_rejected(self):
        methods = self.replies["http://see/methods"]["methods"]
        methods[1] = methods[0]
        with self.assertRaisesRegex(RuntimeError, "inconsistent"):
            self.validate()

    def test_missing_schema_is_not_treated_as_success(self):
        url = "http://core/models/integrated-lca/versions/0.2.0/schema"
        original_get = checker.get_json

        def fetch(target, token=None):
            return original_get(target, token) if target == url else self.replies[target]

        with patch.object(checker, "get_json", side_effect=fetch):
            with patch.object(checker, "urlopen", side_effect=HTTPError(url, 404, "Not Found", {}, None)):
                with contextlib.redirect_stdout(io.StringIO()), self.assertRaisesRegex(RuntimeError, "HTTP 404"):
                    checker.validate("http://see", self.catalog_path, "http://core")

    def test_invalid_schema_body_is_rejected(self):
        self.replies["http://core/models/product-system/versions/0.0.1/schema"] = {"status": "ok"}
        with self.assertRaisesRegex(RuntimeError, "did not return a JSON Schema"):
            self.validate()

    def test_http_request_sends_bearer_token(self):
        with patch.object(checker, "urlopen", return_value=io.BytesIO(b'{"type": "object"}')) as fetch:
            self.assertEqual(checker.get_json("http://core/schema", "test-token"), {"type": "object"})
        self.assertEqual(fetch.call_args.args[0].get_header("Authorization"), "Bearer test-token")

    def test_non_json_response_is_rejected(self):
        with patch.object(checker, "urlopen", return_value=io.BytesIO(b'<html>failure</html>')):
            with self.assertRaisesRegex(RuntimeError, "valid JSON"):
                checker.get_json("http://core/schema")


if __name__ == "__main__":
    unittest.main()
