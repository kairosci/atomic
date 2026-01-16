#!/usr/bin/env zsh
# @file rename-btrfs.sh
# @brief Renames BTRFS filesystem labels
# @description
#   Renames filesystem labels for /var and /var/home to 'fedora'.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

# @description Renames BTRFS labels to 'fedora'.
rename-btrfs-labels() {
    ensure-root
    log-info "Renaming BTRFS labels"

    btrfs filesystem label /var fedora
    btrfs filesystem label /var/home fedora

    log-success "BTRFS labels renamed"
}

# @description Main entry point.
main() {
    rename-btrfs-labels
}

main "$@"
