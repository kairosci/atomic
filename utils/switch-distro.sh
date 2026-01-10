#!/usr/bin/env zsh
# =============================================================================
# Switch Distro
# Switches between Fedora Silverblue and Kionite (and vice versa)
# =============================================================================

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../lib/common.sh"

# =============================================================================
# Functions
# =============================================================================

get-os-version() {
    rpm -E %fedora
}

switch-distro() {
    ensure-root
    
    local current_distro
    current_distro="$(detect-distro)"
    
    local os_version
    os_version="$(get-os-version)"
    
    log-info "Current configuration:"
    log-info "  Distro:  $current_distro"
    log-info "  Version: Fedora $os_version"
    echo ""
    
    echo "Select target distro:"
    echo "  [1] Silverblue (GNOME)"
    echo "  [2] Kinoite (KDE Plasma)"
    echo "  [3] Cosmic (COSMIC DE)"
    echo "  [4] Cancel"
    
    read -rp "> " choice
    
    local target_distro=""
    local target_ref=""
    
    case "$choice" in
        1)
            target_distro="silverblue"
            target_ref="fedora:fedora/${os_version}/x86_64/silverblue"
            ;;
        2)
            target_distro="kinoite"
            target_ref="fedora:fedora/${os_version}/x86_64/kinoite"
            ;;
        3)
            target_distro="cosmic"
            target_ref="fedora:fedora/${os_version}/x86_64/cosmic-atomic"
            ;;
        *)
            log-info "Operation cancelled."
            exit 0
            ;;
    esac
    
    if [[ "$current_distro" == "$target_distro" ]]; then
        log-warn "You are already on $target_distro."
        exit 0
    fi
    
    echo ""
    log-info "Target configuration:"
    log-info "  Distro:  $target_distro"
    log-info "  Ref:     $target_ref"
    echo ""
    log-warn "WARNING: This operation will rebase your system to $target_distro."
    log-warn "This requires a large download and a system reboot."
    log-warn "Any layered packages incompatible with the new desktop environment might cause issues."
    echo ""
    
    read -rp "Are you sure you want to proceed? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log-info "Operation cancelled."
        exit 0
    fi
    
    if confirm "Do you want to RESET your home directory (delete old configs)?"; then
        log-info "Performing home directory reset..."
        
        # We need to run this as the real user, not root (since switch-distro runs as root)
        # But wait, switch-distro calls ensure-root.
        # We should use sudo -u $SUDO_USER to run the reset script if we are root.
        
        local user_script="$SCRIPT_DIR/reset-home.sh"
        local real_user
        real_user="$(get-real-user)"
        
        if [[ -f "$user_script" ]]; then
            sudo -u "$real_user" "$user_script"
        else
            log-error "Reset script not found at $user_script"
        fi
    fi

    log-info "Starting rebase to $target_distro..."
    rpm-ostree rebase "$target_ref"
    
    log-success "Rebase initiated successfully."
    log-info "Please reboot your system to boot into $target_distro."
}

# =============================================================================
# Entry Point
# =============================================================================

main() {
    switch-distro
}

main "$@"
