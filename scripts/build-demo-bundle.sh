#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bundle="$root/bundles/demo"

rm -rf "$bundle"
mkdir -p "$bundle/packages"

docker run --rm -v "$bundle/packages:/bundle" almalinux:9 bash -lc '
  set -euo pipefail
  dnf -y install dnf-plugins-core createrepo_c >/dev/null
  dnf download --destdir /bundle --resolve --alldeps tzdata >/dev/null
  createrepo_c /bundle >/dev/null
'

cat > "$bundle/RELEASE_NOTES.md" <<'EOF'
# Demo patch bundle

This bundle contains a small AlmaLinux package set for exercising the offline
transport, repository, approval, rollout, and evidence paths. It is not a claim
that the included package is currently vulnerable.

A production security bundle must mirror repository updateinfo metadata and be
selected from approved vendor advisories.
EOF

"$root/.venv/bin/patchctl" manifest --bundle-dir "$bundle" \
  --platform almalinux-9 --purpose offline-patch-demo
"$root/.venv/bin/patchctl" verify --bundle-dir "$bundle"
echo "Demo bundle ready: $bundle"
