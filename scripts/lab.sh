#!/usr/bin/env bash
set -euo pipefail

action="${1:-Assess}"
apply="${2:-false}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANSIBLE_CONFIG="$root/ansible/ansible.cfg"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/airgap-patch-orchestrator"
mkdir -p "$runtime_dir"
if [[ -f "$root/lab/ssh/id_ed25519" ]]; then
  cp "$root/lab/ssh/id_ed25519" "$runtime_dir/id_ed25519"
  chmod 0600 "$runtime_dir/id_ed25519"
  export AIRGAP_SSH_KEY="$runtime_dir/id_ed25519"
fi

require_venv() {
  if [[ ! -x "$root/.venv/bin/python" ]]; then
    echo "Missing .venv. Run pwsh ./scripts/bootstrap.ps1 first." >&2
    exit 2
  fi
}

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    echo "Docker Compose is not installed in WSL." >&2
    exit 2
  fi
}

case "$action" in
  Up)
    test -f "$root/lab/ssh/authorized_keys" || { echo "Run bootstrap first." >&2; exit 2; }
    compose -f "$root/lab/compose.yml" up -d --build
    ;;
  Down)
    compose -f "$root/lab/compose.yml" down --remove-orphans
    ;;
  Assess)
    require_venv
    cd "$root/ansible"
    "$root/.venv/bin/ansible-playbook" playbooks/assess.yml
    ;;
  BuildBundle)
    require_venv
    "$root/scripts/build-demo-bundle.sh"
    ;;
  VerifyBundle)
    require_venv
    "$root/.venv/bin/patchctl" verify --bundle-dir "$root/bundles/demo"
    ;;
  Patch)
    require_venv
    if [[ "$apply" != "true" ]]; then
      echo "Patch is locked. Re-run with -Apply to acknowledge mutation." >&2
      exit 2
    fi
    cd "$root/ansible"
    "$root/.venv/bin/ansible-playbook" playbooks/patch.yml \
      -e patch_apply=true -e patch_security_only=false
    ;;
  Test)
    require_venv
    "$root/.venv/bin/pytest" -q
    cd "$root/ansible"
    "$root/.venv/bin/ansible-playbook" playbooks/assess.yml --syntax-check
    "$root/.venv/bin/ansible-playbook" playbooks/patch.yml --syntax-check
    ;;
  *)
    echo "Unknown action: $action" >&2
    exit 2
    ;;
esac
