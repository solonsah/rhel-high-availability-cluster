#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repository_root}"

required_commands=(
  ansible-galaxy
  ansible-lint
  ansible-playbook
  shellcheck
  yamllint
)

for required_command in "${required_commands[@]}"; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "${required_command}" >&2
    exit 1
  fi
done

printf '%s\n' 'Checking YAML files...'
yamllint .

printf '%s\n' 'Checking shell scripts...'
shellcheck scripts/*.sh

printf '%s\n' 'Checking required Ansible collection...'
if ! ansible-galaxy collection list ansible.posix | grep -q 'ansible\.posix'; then
  printf '%s\n' 'Required collection ansible.posix is not installed.' >&2
  exit 1
fi

printf '%s\n' 'Running Ansible lint...'
ansible-lint

playbooks=(
  ansible/playbooks/audit.yml
  ansible/playbooks/deploy.yml
  ansible/playbooks/rollback.yml
)

for playbook in "${playbooks[@]}"; do
  printf 'Checking syntax: %s\n' "${playbook}"
  ansible-playbook --syntax-check "${playbook}"
done

printf '%s\n' 'All static validation checks passed.'
