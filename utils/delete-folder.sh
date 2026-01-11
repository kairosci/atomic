#!/usr/bin/env zsh
# *****************************************************************************
# Delete Folder
# Interactively deletes folders matching a pattern
# *****************************************************************************

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../lib/common.sh"

# *****************************************************************************
# Main Function
# *****************************************************************************

delete-folders() {
    read -rp "Folder name pattern: " folder_name
    
    if [[ -z "$folder_name" ]]; then
        log-error "No folder name provided"
        return 1
    fi
    
    log-warn "This will delete all folders matching '*$folder_name*'"
    read -rp "Continue? [y/N] " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log-info "Cancelled"
        return 0
    fi
    
    log-info "Searching and deleting folders..."
    sudo find / -type d -name "*$folder_name*" -exec rm -rf {} + 2>/dev/null || log-warn "Failed to delete some folders matching pattern"
    
    log-success "Done"
}

# *****************************************************************************
# Entry Point
# *****************************************************************************

main() {
    delete-folders
}

main "$@"
