#!/usr/bin/env zsh
# =============================================================================
# Rename BTRFS Labels
# Renames filesystem labels for /var and /var/home
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# Main Function
# =============================================================================

rename-btrfs-labels() {
    ensure-root
    log-info "Renaming BTRFS labels"
    
    btrfs filesystem label /var fedora
    btrfs filesystem label /var/home fedora
    
    log-success "BTRFS labels renamed"
}

# =============================================================================
# Entry Point
# =============================================================================

main() {
    rename-btrfs-labels
}

main "$@"
