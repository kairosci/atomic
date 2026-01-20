#!/usr/bin/bash
# =============================================================================
# Unset Folder Protection
# Removes protection from folders (removes anchor files)
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# =============================================================================
# Constants
# =============================================================================

readonly ANCHOR_FILE=".state_protected"

# =============================================================================
# Functions
# =============================================================================

unprotect-directory-recursive() {
    local target_dir="$1"
    
    if [[ ! -d "$target_dir" ]]; then
        log-warn "Skipping missing directory: $target_dir"
        return 0
    fi
    
    log-info "Scanning $target_dir recursively to remove protection"
    
    find "$target_dir" -mount -type d | while read -r dir; do
        if [[ -f "$dir/$ANCHOR_FILE" ]]; then
            log-info "Unprotecting: $dir"
            chattr -i "$dir/$ANCHOR_FILE" 2>/dev/null || true
            rm -f "$dir/$ANCHOR_FILE"
        fi
    done
}

# =============================================================================
# Entry Point
# =============================================================================

main() {
    require-root
    
    local user_home
    user_home="$(get-user-home)"
    
    local -a targets=("$user_home")
    
    for root in "${targets[@]}"; do
        if [[ -d "$root" ]]; then
            log-info "Removing protection from: $root"
            unprotect-directory-recursive "$root"
        else
            log-warn "Target not found: $root"
        fi
    done
    
    log-success "Folder protection removed"
}

main "$@"
