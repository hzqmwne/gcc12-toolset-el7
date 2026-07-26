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
CORE_SPECS = (
    "gcc12-toolset-runtime.spec",
    "gcc12-toolset-binutils.spec",
    "gcc12-toolset-gcc.spec",
)


def repository_files() -> list[pathlib.Path]:
    output = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
        text=True,
        encoding="utf-8",
    )
    return [ROOT / line for line in output.splitlines() if line]


def spec_release(spec: pathlib.Path) -> str | None:
    match = re.search(r"^Release:\s*([^\s]+)", spec.read_text(encoding="utf-8"), re.M)
    return match.group(1) if match else None


def validate_spec_invariants(errors: list[str]) -> None:
    specs_dir = ROOT / "rpm" / "SPECS"
    releases = {name: spec_release(specs_dir / name) for name in CORE_SPECS}
    if None in releases.values():
        errors.append("core RPM specs must each declare Release")
    elif len(set(releases.values())) != 1:
        rendered = ", ".join(f"{name}={release}" for name, release in releases.items())
        errors.append(f"core RPM spec Releases must stay synchronized: {rendered}")

    for spec in specs_dir.glob("*.spec"):
        text = spec.read_text(encoding="utf-8")
        if not re.search(r"^BuildArch:\s*noarch\s*$", text, re.M):
            continue
        name_match = re.search(r"^Name:\s*(\S+)", text, re.M)
        if not name_match:
            errors.append(f"{spec.relative_to(ROOT)}: noarch spec has no Name")
            continue
        name = name_match.group(1)
        if re.search(rf"^Requires:\s*{re.escape(name)}%\{{\?_isa\}}(?:\s|$)", text, re.M):
            errors.append(
                f"{spec.relative_to(ROOT)}: noarch spec must not require "
                f"its own package name with %{{?_isa}}"
            )


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

    validate_spec_invariants(errors)

    for path in repository_files():
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT).as_posix()
        if path.suffix not in TEXT_SUFFIXES and not path.name.endswith("Dockerfile"):
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
