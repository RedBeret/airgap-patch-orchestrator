#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for command_name in python3 ssh-keygen docker; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 2
  fi
done

if ! docker version >/dev/null 2>&1; then
  echo "Docker is installed but the daemon is not reachable from WSL." >&2
  exit 2
fi

if [[ ! -d "$root/.venv" ]]; then
  python3 -m venv "$root/.venv"
fi

"$root/.venv/bin/python" -m pip install --upgrade pip
"$root/.venv/bin/pip" install -r "$root/requirements-dev.txt" -e "$root"

mkdir -p "$root/lab/ssh"
if [[ ! -f "$root/lab/ssh/id_ed25519" ]]; then
  ssh-keygen -q -t ed25519 -N "" -f "$root/lab/ssh/id_ed25519"
fi
cp "$root/lab/ssh/id_ed25519.pub" "$root/lab/ssh/authorized_keys"
chmod 0600 "$root/lab/ssh/id_ed25519" "$root/lab/ssh/authorized_keys"
chmod 0644 "$root/lab/ssh/id_ed25519.pub"

echo "Bootstrap complete. Run: ./scripts/lab.sh doctor"
