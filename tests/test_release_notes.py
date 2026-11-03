from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from extract_release_notes import extract_release_notes


class ReleaseNotesTests(unittest.TestCase):
    def test_current_release_excludes_older_entries(self):
        notes = extract_release_notes((ROOT / "CHANGELOG.md").read_text(), "v0.0.3")
        self.assertIn("Optional SEE Impacts deployment", notes)
        self.assertNotIn("Initial deployment template structure", notes)
        self.assertNotIn("Optional Compose profile for `re-indicators", notes)

    def test_previous_release_does_not_pick_the_first_entry(self):
        notes = extract_release_notes((ROOT / "CHANGELOG.md").read_text(), "v0.0.2")
        self.assertIn("Optional Compose profile for `re-indicators", notes)
        self.assertNotIn("Optional SEE Impacts deployment", notes)
        self.assertNotIn("Initial deployment template structure", notes)

    def test_tag_without_v_is_supported(self):
        notes = extract_release_notes((ROOT / "CHANGELOG.md").read_text(), "0.0.1")
        self.assertIn("Initial deployment template structure", notes)

    def test_version_matching_is_exact(self):
        changelog = "## [1.2.30] - date\nWrong entry\n## [1.2.3] - date\nRight entry\n"
        self.assertEqual(extract_release_notes(changelog, "v1.2.3"), "Right entry\n")

    def test_missing_entry_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "found 0"):
            extract_release_notes("## [1.0.0]\nChanges\n", "v2.0.0")

    def test_duplicate_entry_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "found 2"):
            extract_release_notes("## [1.0.0]\nFirst\n## [1.0.0]\nSecond\n", "v1.0.0")

    def test_empty_entry_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "is empty"):
            extract_release_notes("## [1.0.0]\n\n## [0.9.0]\nOlder\n", "v1.0.0")

    def test_cli_handles_future_prerelease_without_code_changes(self):
        with tempfile.TemporaryDirectory() as directory:
            changelog = Path(directory) / "CHANGELOG.md"
            changelog.write_text(
                "# Changelog\n\n## [Unreleased]\nLater work\n\n"
                "## [4.2.0-rc.1] - date\n### Added\n- Future change\n\n"
                "## [4.1.0] - date\nOlder work\n"
            )
            result = subprocess.run(
                [sys.executable, "-B", str(ROOT / "scripts/extract_release_notes.py"),
                 "v4.2.0-rc.1", "--changelog", str(changelog)],
                capture_output=True, text=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "### Added\n- Future change\n")


if __name__ == "__main__":
    unittest.main()
