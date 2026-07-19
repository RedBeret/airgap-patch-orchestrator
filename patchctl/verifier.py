"""Dependency-free, fail-closed patch bundle verification."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class VerificationResult:
    ok: bool
    errors: tuple[str, ...]
    checked_files: int


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_bundle(bundle_dir: Path) -> VerificationResult:
    bundle_dir = bundle_dir.resolve()
    manifest_path = bundle_dir / "manifest.json"
    if not manifest_path.is_file():
        return VerificationResult(False, ("manifest.json is missing",), 0)

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return VerificationResult(False, (f"manifest.json is invalid: {exc}",), 0)

    files = manifest.get("files")
    if not isinstance(files, dict) or not files:
        return VerificationResult(False, ("manifest files map is empty or invalid",), 0)

    errors: list[str] = []
    expected = set(files)
    actual = {
        path.relative_to(bundle_dir).as_posix()
        for path in bundle_dir.rglob("*")
        if path.is_file() and path.name not in {"manifest.json", ".verified"}
    }

    for relative_path in sorted(expected):
        candidate = (bundle_dir / relative_path).resolve()
        try:
            candidate.relative_to(bundle_dir)
        except ValueError:
            errors.append(f"unsafe manifest path: {relative_path}")
            continue
        if not candidate.is_file():
            errors.append(f"missing file: {relative_path}")
            continue
        expected_digest = files[relative_path]
        actual_digest = sha256_file(candidate)
        if actual_digest != expected_digest:
            errors.append(f"checksum mismatch: {relative_path}")

    for relative_path in sorted(actual - expected):
        errors.append(f"unexpected file: {relative_path}")

    return VerificationResult(not errors, tuple(errors), len(expected))
