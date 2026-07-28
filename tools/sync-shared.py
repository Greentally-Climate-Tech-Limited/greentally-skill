#!/usr/bin/env python3
"""Synchronize shared Greentally Skill resources and check for drift."""

from __future__ import annotations

import argparse
import filecmp
import shutil
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SHARED = ROOT / "shared"
SKILLS = {
    "greentally-analyze-document": (
        "cli-operation.md",
        "extraction-rules.md",
        "document-observation-v2.schema.json",
        "emission-source-contract-v2.schema.json",
    ),
    "greentally-match-factors": (
        "cli-operation.md",
        "factor-matching.md",
        "emission-source-contract-v2.schema.json",
    ),
    "greentally-submit-analysis": (
        "cli-operation.md",
        "review-and-submit.md",
    ),
    "greentally-process-document": (
        "cli-operation.md",
        "extraction-rules.md",
        "factor-matching.md",
        "review-and-submit.md",
        "document-observation-v2.schema.json",
        "emission-source-contract-v2.schema.json",
    ),
}
INSTALLERS = ("install.sh", "install.ps1")


def pairs() -> list[tuple[Path, Path]]:
    result: list[tuple[Path, Path]] = []
    for skill, references in SKILLS.items():
        for name in references:
            result.append(
                (SHARED / "references" / name, ROOT / skill / "references" / name)
            )
        for name in INSTALLERS:
            result.append((SHARED / "scripts" / name, ROOT / skill / "scripts" / name))
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check", action="store_true", help="report drift without writing files"
    )
    args = parser.parse_args()

    failures: list[str] = []
    for source, target in pairs():
        if not source.is_file():
            failures.append(f"missing shared source: {source.relative_to(ROOT)}")
            continue
        if args.check:
            if not target.is_file() or not filecmp.cmp(source, target, shallow=False):
                failures.append(f"out of sync: {target.relative_to(ROOT)}")
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        shutil.copymode(source, target)

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("Shared Skill resources are in sync.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
