#!/usr/bin/env python3
"""Extract the changelog entry matching a release tag."""

import argparse
from pathlib import Path
import re


def extract_release_notes(changelog, tag):
    version = tag.removeprefix("v")
    headings = list(re.finditer(r"^##[ \t]+(.+)$", changelog, re.MULTILINE))
    entries = []
    for index, heading in enumerate(headings):
        label = re.match(r"\[([^\]]+)\](?:[ \t]|$)", heading.group(1))
        if label is None or label.group(1) != version:
            continue
        end = headings[index + 1].start() if index + 1 < len(headings) else len(changelog)
        entries.append(changelog[heading.end():end].strip())
    if len(entries) != 1:
        raise ValueError(f"Expected exactly one changelog entry for {tag}; found {len(entries)}")
    if not entries[0]:
        raise ValueError(f"The changelog entry for {tag} is empty")
    return entries[0] + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tag")
    parser.add_argument("--changelog", type=Path, default=Path("CHANGELOG.md"))
    args = parser.parse_args()
    try:
        notes = extract_release_notes(args.changelog.read_text(encoding="utf-8"), args.tag)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Release notes could not be generated: {error}\n")
    print(notes, end="")


if __name__ == "__main__":
    main()
