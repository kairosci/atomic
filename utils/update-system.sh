#!/usr/bin/env zsh
# =============================================================================
# Update System
# Performs system update, Flatpak update, and cleanup
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# =============================================================================
# Functions
# =============================================================================

update-system() {
    log-info "Updating system (rpm-ostree)"
    rpm-ostree reload
    rpm-ostree refresh-md
    rpm-ostree upgrade
    log-success "System updated"
}

update-flatpak() {
    log-info "Updating Flatpaks"
    flatpak update -y
    log-success "Flatpaks updated"
}

cleanup() {
    log-info "Cleaning up system"
    
    log-info "Cleaning rpm-ostree base"
    rpm-ostree cleanup --base -m
    
    log-info "Removing unused Flatpak runtimes"
    flatpak uninstall --unused --delete-data -y || true
    
    log-info "Vacuuming system logs"
    journalctl --vacuum-files=0
    journalctl --vacuum-time=2weeks
    
    log-success "Cleanup completed"
}

# =============================================================================
# Entry Point
# =============================================================================

main() {
    ensure-root
    update-system
    update-flatpak
    cleanup
    
    echo ""
    log-success "Update and cleanup completed!"
    log-info "You may need to reboot to apply rpm-ostree changes."
}

main "$@"
