#!/usr/bin/bash
# =============================================================================
# Switch Distro
# Switches between Fedora Silverblue and Kionite (and vice versa)
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    
    local target_distro=""
    local target_ref=""
    
    case "$current_distro" in
        silverblue)
            target_distro="kinoite"
            target_ref="fedora:fedora/${os_version}/x86_64/kinoite"
            ;;
        kionite)
            target_distro="silverblue"
            target_ref="fedora:fedora/${os_version}/x86_64/silverblue"
            ;;
        *)
            log-error "Unknown or unsupported current distro: $current_distro"
            exit 1
            ;;
    esac
    
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
