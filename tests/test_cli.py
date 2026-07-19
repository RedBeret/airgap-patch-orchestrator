import json
from argparse import Namespace

from patchctl.cli import _manifest, _verify
from patchctl.verifier import verify_bundle


def test_manifest_round_trip(tmp_path) -> None:
    packages = tmp_path / "packages"
    packages.mkdir()
    (packages / "example.rpm").write_bytes(b"rpm-placeholder")
    result = _manifest(
        Namespace(bundle_dir=str(tmp_path), platform="almalinux-9", purpose="test")
    )
    assert result == 0
    manifest = json.loads((tmp_path / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["platform"] == "almalinux-9"
    assert verify_bundle(tmp_path).ok


def test_failed_reverification_removes_marker(tmp_path) -> None:
    packages = tmp_path / "packages"
    packages.mkdir()
    rpm = packages / "example.rpm"
    rpm.write_bytes(b"original")
    args = Namespace(bundle_dir=str(tmp_path), platform="almalinux-9", purpose="test")
    assert _manifest(args) == 0
    assert _verify(Namespace(bundle_dir=str(tmp_path))) == 0
    assert (tmp_path / ".verified").exists()

    rpm.write_bytes(b"modified-after-verification")

    assert _verify(Namespace(bundle_dir=str(tmp_path))) == 2
    assert not (tmp_path / ".verified").exists()


def test_rebuilding_manifest_invalidates_marker(tmp_path) -> None:
    packages = tmp_path / "packages"
    packages.mkdir()
    (packages / "example.rpm").write_bytes(b"original")
    args = Namespace(bundle_dir=str(tmp_path), platform="almalinux-9", purpose="test")
    assert _manifest(args) == 0
    assert _verify(Namespace(bundle_dir=str(tmp_path))) == 0

    assert _manifest(args) == 0

    assert not (tmp_path / ".verified").exists()
