#!/usr/bin/env python3
"""Audit release APK contents without third-party dependencies."""

from __future__ import annotations

import argparse
import re
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent

FORBIDDEN_PREFIXES = (
    "assets/tests/",
    "assets/tools/",
    "assets/store/",
    "assets/art/troupe/v1/",
    "assets/art/troupe/v2/",
    "assets/art/enemies/v2/",
    "assets/art/enemies/_pre_v2_bak/",
    "assets/audio/ui_src/",
)


def live_sources() -> list[Path]:
    sources: list[Path] = []
    sources.extend(sorted((ROOT / "art" / "troupe" / "v3").glob("*.png")))
    sources.extend(sorted((ROOT / "art" / "enemies").glob("*.png")))
    sources.extend(sorted((ROOT / "art" / "bg").glob("*.png")))
    sources.append(ROOT / "art" / "ui" / "sword.png")

    ui_sfx = (ROOT / "game" / "autoload" / "UiSfx.gd").read_text(encoding="utf-8")
    for match in re.finditer(r'"(res://audio/ui/[^"]+\.(?:wav|ogg))"', ui_sfx):
        sources.append(ROOT / match.group(1).removeprefix("res://"))

    unique: dict[str, Path] = {}
    for source in sources:
        unique[source.as_posix().lower()] = source
    return list(unique.values())


def imported_artifact(zf: zipfile.ZipFile, source: Path) -> tuple[str | None, str | None]:
    relative = source.relative_to(ROOT).as_posix()
    import_entry = f"assets/{relative}.import"
    try:
        text = zf.read(import_entry).decode("utf-8")
    except KeyError:
        return import_entry, None
    match = re.search(r'path="res://\.godot/imported/([^"]+)"', text)
    if match is None:
        return import_entry, ""
    return import_entry, f"assets/.godot/imported/{match.group(1)}"


def audit(apk: Path, min_mb: float, max_mb: float) -> list[str]:
    failures: list[str] = []
    if not apk.is_file():
        return [f"APK does not exist: {apk}"]

    size_mb = apk.stat().st_size / (1024 * 1024)
    if size_mb < min_mb or size_mb > max_mb:
        failures.append(
            f"APK size {size_mb:.1f} MB is outside allowed range "
            f"{min_mb:.1f}-{max_mb:.1f} MB"
        )

    try:
        with zipfile.ZipFile(apk) as zf:
            names = set(zf.namelist())
            bad = sorted(
                name
                for name in names
                if any(name.startswith(prefix) for prefix in FORBIDDEN_PREFIXES)
            )
            if bad:
                failures.append(
                    "forbidden development/archive files are packaged: "
                    + ", ".join(bad[:10])
                )

            expected = live_sources()
            portrait_count = 0
            for source in expected:
                if not source.is_file():
                    failures.append(f"required source is missing before APK audit: {source}")
                    continue
                import_entry, artifact = imported_artifact(zf, source)
                if import_entry not in names:
                    failures.append(
                        f"required resource is absent from APK: "
                        f"{source.relative_to(ROOT).as_posix()}"
                    )
                    continue
                if artifact == "":
                    failures.append(f"invalid import metadata in APK: {import_entry}")
                    continue
                if artifact is None or artifact not in names:
                    failures.append(
                        f"imported artifact is absent from APK: "
                        f"{source.relative_to(ROOT).as_posix()}"
                    )
                    continue
                if source.parent == ROOT / "art" / "troupe" / "v3":
                    portrait_count += 1

            if portrait_count != 10:
                failures.append(
                    f"expected 10 live troupe portraits in APK, found {portrait_count}"
                )
    except zipfile.BadZipFile:
        failures.append(f"invalid APK/ZIP file: {apk}")

    print(f"APK: {apk}")
    print(f"Size: {size_mb:.1f} MB")
    if failures:
        print(f"Audit failed: {len(failures)} problem(s)")
        for failure in failures:
            print(f"  - {failure}")
    else:
        print("Audit passed: required live content present; archives and test tools absent.")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("--min-mb", type=float, default=60.0)
    parser.add_argument("--max-mb", type=float, default=90.0)
    args = parser.parse_args()
    return 1 if audit(args.apk.resolve(), args.min_mb, args.max_mb) else 0


if __name__ == "__main__":
    sys.exit(main())
