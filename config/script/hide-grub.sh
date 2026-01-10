#!/usr/bin/env zsh
# *****************************************************************************
# Hide GRUB Menu
# Sets GRUB timeout to 0 for instant boot
# *****************************************************************************

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

# *****************************************************************************
# Constants
# *****************************************************************************



# *****************************************************************************
# Main Function
# *****************************************************************************

hide-grub() {
    ensure-root
    log-info "Hiding GRUB menu"
    
    local grub_config=""
    
    # Check common GRUB config locations
    if [[ -f "/boot/grub2/grub.cfg" ]]; then
        grub_config="/boot/grub2/grub.cfg"
    elif [[ -f "/boot/efi/EFI/fedora/grub.cfg" ]]; then
        grub_config="/boot/efi/EFI/fedora/grub.cfg"
    else
        log-warn "GRUB config not found in standard locations"
        return 0
    fi
    
    log-info "Found GRUB config at: $grub_config"
    
    # Backup original
    cp "$grub_config" "${grub_config}.bak"
    
    # Set timeout to 0
    sed -i 's/^set timeout=.*/set timeout=0/' "$grub_config"
    
    # Make read-only to prevent regeneration
    chmod 444 "$grub_config"
    
    log-success "GRUB menu hidden"
}

# *****************************************************************************
# Entry Point
# *****************************************************************************

main() {
    hide-grub
}

main "$@"
