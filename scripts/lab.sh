#!/usr/bin/env bash
set -euo pipefail

action="${1:-assess}"
action="${action,,}"
apply="${2:-false}"
if [[ "$apply" == "--apply" ]]; then
  apply="true"
fi
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
    echo "Missing .venv. Run ./scripts/bootstrap.sh from WSL or bootstrap.ps1 from PowerShell." >&2
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

doctor() {
  local failed=0
  for command_name in python3 docker ssh ssh-keygen; do
    if command -v "$command_name" >/dev/null 2>&1; then
      echo "ok command $command_name"
    else
      echo "missing command $command_name" >&2
      failed=1
    fi
  done
  if docker version >/dev/null 2>&1; then
    echo "ok docker daemon"
  else
    echo "unavailable docker daemon" >&2
    failed=1
  fi
  if docker compose version >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1; then
    echo "ok docker compose"
  else
    echo "missing docker compose" >&2
    failed=1
  fi
  if [[ -x "$root/.venv/bin/ansible-playbook" ]]; then
    echo "ok ansible environment"
  else
    echo "missing ansible environment; run ./scripts/bootstrap.sh" >&2
    failed=1
  fi
  if [[ -f "$root/lab/ssh/authorized_keys" && -f "$root/lab/ssh/id_ed25519" ]]; then
    echo "ok lab ssh key"
  else
    echo "missing lab ssh key; run ./scripts/bootstrap.sh" >&2
    failed=1
  fi
  return "$failed"
}

case "$action" in
  up)
    test -f "$root/lab/ssh/authorized_keys" || { echo "Run bootstrap first." >&2; exit 2; }
    compose -f "$root/lab/compose.yml" up -d --build
    ;;
  down)
    compose -f "$root/lab/compose.yml" down --remove-orphans
    ;;
  assess)
    require_venv
    cd "$root/ansible"
    "$root/.venv/bin/ansible-playbook" playbooks/assess.yml
    ;;
  buildbundle|build-bundle)
    require_venv
    "$root/scripts/build-demo-bundle.sh"
    ;;
  verifybundle|verify-bundle)
    require_venv
    "$root/.venv/bin/patchctl" verify --bundle-dir "$root/bundles/demo"
    ;;
  patch)
    require_venv
    if [[ "$apply" != "true" ]]; then
      echo "Patch is locked. Re-run with --apply in WSL or -Apply in PowerShell." >&2
      exit 2
    fi
    cd "$root/ansible"
    "$root/.venv/bin/ansible-playbook" playbooks/patch.yml \
      -e patch_apply=true -e patch_security_only=false
    ;;
  test)
    require_venv
    "$root/.venv/bin/pytest" -q
    cd "$root/ansible"
    "$root/.venv/bin/ansible-playbook" playbooks/assess.yml --syntax-check
    "$root/.venv/bin/ansible-playbook" playbooks/patch.yml --syntax-check
    cd "$root"
    "$root/.venv/bin/ansible-lint" ansible/playbooks ansible/roles
    bash -n scripts/bootstrap.sh scripts/build-demo-bundle.sh scripts/lab.sh
    ;;
  doctor)
    doctor
    ;;
  status)
    compose -f "$root/lab/compose.yml" ps
    ;;
  *)
    echo "Unknown action: $action" >&2
    exit 2
    ;;
esac
