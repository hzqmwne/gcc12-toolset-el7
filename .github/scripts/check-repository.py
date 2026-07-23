#!/usr/bin/env python3
"""Fast checks that run before the expensive toolchain build."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parents[2]
SEMVER = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
TEXT_SUFFIXES = {"", ".md", ".py", ".sh", ".spec", ".yaml", ".yml"}


def repository_files() -> list[pathlib.Path]:
    output = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
        text=True,
        encoding="utf-8",
    )
    return [ROOT / line for line in output.splitlines() if line]


def main() -> int:
    errors: list[str] = []
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    if not SEMVER.fullmatch(version):
        errors.append(f"VERSION must be stable SemVer, got {version!r}")

    ref_name = subprocess.run(
        ["git", "describe", "--tags", "--exact-match"],
        cwd=ROOT,
        text=True,
        encoding="utf-8",
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    ).stdout.strip()
    if ref_name and ref_name != f"v{version}":
        errors.append(f"tag {ref_name!r} does not match VERSION {version!r}")

    for path in repository_files():
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT).as_posix()
        if path.suffix not in TEXT_SUFFIXES and path.name != "Dockerfile":
            continue
        data = path.read_bytes()
        if b"\0" in data:
            continue
        if b"\r" in data:
            errors.append(f"{relative}: contains CR/CRLF; Unix LF is required")
        try:
            data.decode("utf-8")
        except UnicodeDecodeError as exc:
            errors.append(f"{relative}: invalid UTF-8 ({exc})")
        if data and not data.endswith(b"\n"):
            errors.append(f"{relative}: missing final newline")

    if errors:
        print("Repository checks failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"Repository checks passed (version {version}, UTF-8, Unix LF).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
