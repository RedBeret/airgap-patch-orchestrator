import hashlib
import json
from pathlib import Path

from patchctl.verifier import verify_bundle


def make_bundle(tmp_path: Path) -> Path:
    packages = tmp_path / "packages"
    packages.mkdir()
    rpm = packages / "demo.rpm"
    rpm.write_bytes(b"synthetic-rpm-content")
    digest = hashlib.sha256(rpm.read_bytes()).hexdigest()
    (tmp_path / "manifest.json").write_text(
        json.dumps({"schema_version": 1, "files": {"packages/demo.rpm": digest}}),
        encoding="utf-8",
    )
    return tmp_path


def test_valid_bundle_passes(tmp_path: Path) -> None:
    result = verify_bundle(make_bundle(tmp_path))
    assert result.ok
    assert result.checked_files == 1


def test_corrupted_bundle_fails(tmp_path: Path) -> None:
    bundle = make_bundle(tmp_path)
    (bundle / "packages/demo.rpm").write_bytes(b"tampered")
    result = verify_bundle(bundle)
    assert not result.ok
    assert result.errors == ("checksum mismatch: packages/demo.rpm",)


def test_unexpected_file_fails(tmp_path: Path) -> None:
    bundle = make_bundle(tmp_path)
    (bundle / "surprise.sh").write_text("echo nope", encoding="utf-8")
    result = verify_bundle(bundle)
    assert not result.ok
    assert "unexpected file: surprise.sh" in result.errors


def test_path_escape_fails(tmp_path: Path) -> None:
    bundle = make_bundle(tmp_path)
    manifest = {"schema_version": 1, "files": {"../outside.rpm": "0" * 64}}
    (bundle / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    result = verify_bundle(bundle)
    assert not result.ok
    assert "unsafe manifest path: ../outside.rpm" in result.errors
