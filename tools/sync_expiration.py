#!/usr/bin/env python3
"""Sync the project expiration date from the README SSOT across the repo.

Single source of truth: ``README.md`` line ``**Expires:** YYYY-MM-DD`` (and its
matching shields.io badge).

Usage:
    python tools/sync_expiration.py                 # sync everything to README SSOT
    python tools/sync_expiration.py 2026-05-22      # set new date, then sync
    python tools/sync_expiration.py --check         # verify, exit non-zero on drift

What it touches:
    - README.md            badge + ``**Expires:**`` + ``**Status:**`` line
    - notebooks/ch00       ``SET DEMO_EXPIRES = '...';`` banner cell
    - **/*.{sql,yaml,yml,ipynb,md,py}   ``(Expires: YYYY-MM-DD)`` in COMMENTs

stdlib-only, idempotent, fails loudly on ambiguity.
"""
from __future__ import annotations

import argparse
import re
import sys
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
README = REPO_ROOT / "README.md"

TARGET_EXTS = {".sql", ".yaml", ".yml", ".ipynb", ".md", ".py"}
EXCLUDE_DIRS = {".git", ".venv-drift", "__pycache__", "datasets", "node_modules"}
SELF_NAME = Path(__file__).name

ISO_DATE = r"(\d{4}-\d{2}-\d{2})"

EXPIRES_COMMENT_RE = re.compile(rf"\(Expires: {ISO_DATE}\)")
SET_DEMO_EXPIRES_RE = re.compile(rf"SET DEMO_EXPIRES = '{ISO_DATE}';")
README_EXPIRES_LINE_RE = re.compile(rf"\*\*Expires:\*\* {ISO_DATE}")
README_STATUS_LINE_RE = re.compile(r"\*\*Status:\*\* (ACTIVE|EXPIRING SOON|EXPIRED)")
README_BADGE_RE = re.compile(
    r"!\[Expires\]\(https://img\.shields\.io/badge/Expires-"
    r"(\d{4})--(\d{2})--(\d{2})-(green|orange|red)\)"
)

STATUS_COLORS = {"ACTIVE": "green", "EXPIRING SOON": "orange", "EXPIRED": "red"}


def status_for(target: str) -> str:
    days = (date.fromisoformat(target) - date.today()).days
    if days < 0:
        return "EXPIRED"
    if days <= 14:
        return "EXPIRING SOON"
    return "ACTIVE"


def read_readme_ssot() -> str:
    text = README.read_text(encoding="utf-8")
    match = README_EXPIRES_LINE_RE.search(text)
    if not match:
        sys.exit(
            "ERROR: README.md is missing the `**Expires:** YYYY-MM-DD` SSOT line. "
            "Add it near the top, then re-run."
        )
    return match.group(1)


def write_readme(new_date: str) -> bool:
    text = README.read_text(encoding="utf-8")
    status = status_for(new_date)
    color = STATUS_COLORS[status]
    badge_date = new_date.replace("-", "--")
    new_text = text
    new_text = README_EXPIRES_LINE_RE.sub(f"**Expires:** {new_date}", new_text)
    new_text = README_STATUS_LINE_RE.sub(f"**Status:** {status}", new_text)
    new_text = README_BADGE_RE.sub(
        f"![Expires](https://img.shields.io/badge/Expires-{badge_date}-{color})",
        new_text,
    )
    if new_text != text:
        README.write_text(new_text, encoding="utf-8")
        return True
    return False


def walk_target_files():
    for path in REPO_ROOT.rglob("*"):
        if not path.is_file():
            continue
        if path.name == SELF_NAME:
            continue
        if any(part in EXCLUDE_DIRS for part in path.relative_to(REPO_ROOT).parts):
            continue
        if path.suffix in TARGET_EXTS:
            yield path


def sync_file(path: Path, new_date: str) -> bool:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return False
    new_text = EXPIRES_COMMENT_RE.sub(f"(Expires: {new_date})", text)
    new_text = SET_DEMO_EXPIRES_RE.sub(f"SET DEMO_EXPIRES = '{new_date}';", new_text)
    if new_text != text:
        path.write_text(new_text, encoding="utf-8")
        return True
    return False


def check_consistency(ssot: str) -> int:
    drift = 0
    text = README.read_text(encoding="utf-8")
    badge = README_BADGE_RE.search(text)
    if badge:
        badge_date = f"{badge.group(1)}-{badge.group(2)}-{badge.group(3)}"
        if badge_date != ssot:
            print(f"DRIFT: README badge = {badge_date} (SSOT: {ssot})")
            drift += 1
    status_line = README_STATUS_LINE_RE.search(text)
    if status_line and status_line.group(1) != status_for(ssot):
        print(f"DRIFT: README status = {status_line.group(1)} (expected {status_for(ssot)})")
        drift += 1
    for path in walk_target_files():
        try:
            body = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        rel = path.relative_to(REPO_ROOT)
        for match in EXPIRES_COMMENT_RE.finditer(body):
            if match.group(1) != ssot:
                print(f"DRIFT: {rel} has (Expires: {match.group(1)})")
                drift += 1
                break
        for match in SET_DEMO_EXPIRES_RE.finditer(body):
            if match.group(1) != ssot:
                print(f"DRIFT: {rel} SET DEMO_EXPIRES = '{match.group(1)}'")
                drift += 1
                break
    return drift


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Sync project expiration date from README.md SSOT."
    )
    parser.add_argument(
        "date",
        nargs="?",
        help="New expiration date in YYYY-MM-DD. If omitted, sync to current README value.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify consistency only; exit non-zero on drift.",
    )
    args = parser.parse_args()

    if args.check:
        ssot = read_readme_ssot()
        drift = check_consistency(ssot)
        if drift:
            print(f"\n{drift} drift(s) detected. SSOT: {ssot}.")
            return 1
        print(f"OK. All occurrences match SSOT ({ssot}, status={status_for(ssot)}).")
        return 0

    if args.date:
        try:
            date.fromisoformat(args.date)
        except ValueError:
            sys.exit(f"ERROR: invalid ISO date: {args.date}")
        readme_changed = write_readme(args.date)
        ssot = args.date
        if readme_changed:
            print(f"Updated README SSOT -> {ssot} ({status_for(ssot)}).")
        else:
            print(f"README already at {ssot}; refreshing other files.")
    else:
        ssot = read_readme_ssot()
        write_readme(ssot)
        print(f"SSOT = {ssot} ({status_for(ssot)}).")

    changed = [p for p in walk_target_files() if sync_file(p, ssot)]
    for p in changed:
        print(f"  updated {p.relative_to(REPO_ROOT)}")
    print(f"\nDone. {len(changed)} file(s) updated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
