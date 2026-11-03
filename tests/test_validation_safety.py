import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class ValidationSafetyTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.bin = self.directory / "bin"
        self.bin.mkdir()
        self.log = self.directory / "commands.jsonl"
        self.environment = {
            **os.environ,
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "VALIDATION_COMMAND_LOG": str(self.log),
        }

    def executable(self, name, code):
        path = self.bin / name
        path.write_text("#!/usr/bin/env python3\n" + code)
        path.chmod(0o755)

    def test_existing_kubernetes_namespace_is_not_modified_or_deleted(self):
        self.executable("kubectl", """
import json, os, sys
with open(os.environ['VALIDATION_COMMAND_LOG'], 'a') as stream:
    stream.write(json.dumps(sys.argv[1:]) + '\\n')
if sys.argv[1] == 'kustomize':
    print('name: registry-catalog\\nschema_url: https://codeberg.org/schema.json')
    sys.exit(0)
if sys.argv[1] == 'create':
    print('AlreadyExists', file=sys.stderr)
    sys.exit(1)
sys.exit(1)
""")
        for overlay in ("dev-see-impacts", "prod-see-impacts", "dev-calculations", "prod-calculations"):
            with self.subTest(overlay=overlay):
                self.log.write_text("")
                result = subprocess.run(
                    ["bash", str(ROOT / "scripts/validate-local-kubernetes.sh")],
                    env={**self.environment, "K8S_OVERLAY": overlay}, capture_output=True, text=True,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("refusing to modify", result.stderr)
                commands = [json.loads(line) for line in self.log.read_text().splitlines()]
                self.assertTrue(any(command[:2] == ["create", "namespace"] for command in commands))
                self.assertFalse(any(command[0] in ("apply", "delete") for command in commands))

    def test_compose_validation_preserves_operator_environment(self):
        repo = self.directory / "repo"
        (repo / "compose").mkdir(parents=True)
        for name in ("docker-compose.yml", ".env.example"):
            shutil.copyfile(ROOT / "compose" / name, repo / "compose" / name)
        shutil.copytree(ROOT / "compose/registry", repo / "compose/registry")
        (repo / "scripts").mkdir()
        shutil.copyfile(ROOT / "scripts/validate-local-compose.sh", repo / "scripts/validate-local-compose.sh")
        operator_environment = repo / "compose/.env"
        operator_environment.write_text("OPERATOR_CONFIGURATION=preserve-this\n")
        self.executable("docker", """
import json, os, sys
with open(os.environ['VALIDATION_COMMAND_LOG'], 'a') as stream:
    stream.write(json.dumps({'args': sys.argv[1:], 'cwd': os.getcwd()}) + '\\n')
""")
        self.executable("curl", "print('200', end='')\n")
        result = subprocess.run(
            ["bash", str(repo / "scripts/validate-local-compose.sh")],
            env={**self.environment, "COMPOSE_PROFILES": ""}, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(operator_environment.read_text(), "OPERATOR_CONFIGURATION=preserve-this\n")
        commands = [json.loads(line) for line in self.log.read_text().splitlines()]
        for command in commands:
            self.assertIn("--project-name", command["args"])
            self.assertNotEqual(Path(command["cwd"]), repo / "compose")
            self.assertFalse(Path(command["cwd"]).exists())


if __name__ == "__main__":
    unittest.main()
