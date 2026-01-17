#!/usr/bin/env zsh
# @file delete-folder.sh
# @brief Interactively deletes folders matching a pattern
# @description
#   Prompts for a folder name pattern and deletes all matching folders.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

# @description Deletes folders matching a user-provided pattern.
delete-folders() {
    read -r "folder_name?Folder name pattern: "

    if [[ -z "$folder_name" ]]; then
        log-error "No folder name provided"
        return 1
    fi

    log-warn "This will delete all folders matching '*$folder_name*'"
    read -r "confirm?Continue? [y/N] "

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log-info "Cancelled"
        return 0
    fi

    log-info "Searching and deleting folders..."
    sudo find / -type d -name "*$folder_name*" -exec rm -rf {} + 2>/dev/null || log-warn "Failed to delete some folders matching pattern"

    log-success "Done"
}

# @description Main entry point.
main() {
    delete-folders
}

main "$@"
