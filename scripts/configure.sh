#!/usr/bin/env zsh
# @file configure.sh
# @brief Fedora Atomic Configuration Index
# @description
#   Detects available distro and runs the appropriate Ansible playbook.
#   Installs Ansible if missing.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../lib/common.sh" # Assumes lib/common.sh exists

main() {
    local distro
    distro=$(detect-distro) # From common.sh

    log-title "Configuration for $distro (via Ansible)"

    # Ensure Ansible is installed
    if ! command -v ansible-playbook &>/dev/null; then
        log-info "Ansible not found. Attempting to install..."
        if command -v rpm-ostree &>/dev/null; then
            if ! rpm-ostree status | grep -q "ansible"; then
                log-warn "Ansible is not layered and not in toolbox. Installing generic version in toolbox might be better."
                log-info "Trying to run in toolbox if available..."
                if command -v toolbox &>/dev/null; then
                     log-info "Please run: toolbox run ansible-playbook ..."
                     log-error "Automatic toolbox execution not yet implemented. Please install ansible: 'rpm-ostree install ansible' and reboot."
                     exit 1
                fi
                # Fallback to rpm-ostree (requires reboot, so we can't continue suitable)
                log-error "Ansible must be installed. Run 'rpm-ostree install ansible' and reboot."
                exit 1
            fi
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y ansible
        else
             log-error "Cannot install ansible. Package manager not found."
             exit 1
        fi
    fi

    local playbook=""
    case "$distro" in
        silverblue)
            playbook="$SCRIPT_DIR/../ansible/playbooks/silverblue.yml"
            ;;
        kionite)
            playbook="$SCRIPT_DIR/../ansible/playbooks/kinoite.yml"
            ;;
        *)
            log-warn "Unsupported distro for full Ansible config: $distro"
            exit 0
            ;;
    esac

    if [[ -f "$playbook" ]]; then
        log-info "Running playbook: $playbook"
        ansible-playbook "$playbook"
    else
        log-error "Playbook not found: $playbook"
        exit 1
    fi
}

main "$@"
