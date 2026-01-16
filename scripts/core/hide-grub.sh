#!/usr/bin/env zsh
# @file hide-grub.sh
# @brief Hides the GRUB boot menu
# @description
#   Sets GRUB timeout to 0 for instant boot and makes the config read-only.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

# @description Finds and returns the GRUB config path.
# @stdout GRUB config path if found
# @exitcode 0 Found
# @exitcode 1 Not found
find-grub-config() {
    if [[ -f "/boot/grub2/grub.cfg" ]]; then
        echo "/boot/grub2/grub.cfg"
    elif [[ -f "/boot/efi/EFI/fedora/grub.cfg" ]]; then
        echo "/boot/efi/EFI/fedora/grub.cfg"
    else
        return 1
    fi
}

# @description Hides the GRUB menu by setting timeout to 0.
hide-grub() {
    ensure-root
    log-info "Hiding GRUB menu"

    local grub_config
    if ! grub_config=$(find-grub-config); then
        log-warn "GRUB config not found in standard locations"
        return 0
    fi

    log-info "Found GRUB config at: $grub_config"

    cp "$grub_config" "${grub_config}.bak"
    sed -i 's/^set timeout=.*/set timeout=0/' "$grub_config"
    chmod 444 "$grub_config"

    log-success "GRUB menu hidden"
}

# @description Main entry point.
main() {
    hide-grub
}

main "$@"
