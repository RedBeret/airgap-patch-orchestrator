"""Command-line interface for patch bundle operations."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from .verifier import verify_bundle


def _verify(args: argparse.Namespace) -> int:
    bundle = Path(args.bundle_dir)
    result = verify_bundle(bundle)
    payload = {
        "ok": result.ok,
        "checked_files": result.checked_files,
        "errors": list(result.errors),
    }
    print(json.dumps(payload, indent=2))
    marker = bundle / ".verified"
    if result.ok:
        marker.write_text("verified\n", encoding="utf-8")
        return 0
    marker.unlink(missing_ok=True)
    return 2


def _manifest(args: argparse.Namespace) -> int:
    bundle = Path(args.bundle_dir).resolve()
    (bundle / ".verified").unlink(missing_ok=True)
    files: dict[str, str] = {}
    for path in sorted(bundle.rglob("*")):
        if path.is_file() and path.name not in {"manifest.json", ".verified"}:
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            files[path.relative_to(bundle).as_posix()] = digest
    if not files:
        print("refusing to create an empty manifest")
        return 2
    payload = {
        "schema_version": 1,
        "platform": args.platform,
        "purpose": args.purpose,
        "files": files,
    }
    (bundle / "manifest.json").write_text(
        json.dumps(payload, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps({"ok": True, "files": len(files)}, indent=2))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="patchctl")
    commands = parser.add_subparsers(dest="command", required=True)
    verify = commands.add_parser("verify", help="verify a transferred bundle")
    verify.add_argument("--bundle-dir", required=True)
    verify.set_defaults(func=_verify)
    manifest = commands.add_parser("manifest", help="create a bundle manifest")
    manifest.add_argument("--bundle-dir", required=True)
    manifest.add_argument("--platform", default="almalinux-9")
    manifest.add_argument("--purpose", default="offline-patch-demo")
    manifest.set_defaults(func=_manifest)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
