#!/usr/bin/env zsh
# *****************************************************************************
# Set Folder Protection
# Protects visible folders with immutable anchor files
# *****************************************************************************

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../lib/common.sh"

# *****************************************************************************
# Constants
# *****************************************************************************

readonly ANCHOR_FILE=".state_protected"

# *****************************************************************************
# Functions
# *****************************************************************************

protect-directory-recursive() {
    local target_dir="$1"
    
    if [[ ! -d "$target_dir" ]]; then
        log-warn "Skipping missing directory: $target_dir"
        return 0
    fi
    
    log-info "Scanning $target_dir recursively"
    
    find "$target_dir" -mount -type d | while read -r dir; do
        # Check if path contains hidden component
        if [[ "$dir" == *"/."* ]]; then
            # Hidden path - cleanup protection
            if [[ -f "$dir/$ANCHOR_FILE" ]]; then
                log-info "Unprotecting: $dir"
                chattr -i "$dir/$ANCHOR_FILE" 2>/dev/null || true
                rm -f "$dir/$ANCHOR_FILE"
            fi
        else
            # Visible path - protect
            if [[ -f "$dir/$ANCHOR_FILE" ]]; then
                continue
            fi
            
            log-info "Protecting: $dir"
            touch "$dir/$ANCHOR_FILE"
            chattr +i "$dir/$ANCHOR_FILE" 2>/dev/null || log-warn "Failed to protect $dir"
        fi
    done
}

# *****************************************************************************
# Entry Point
# *****************************************************************************

main() {
    ensure-root
    
    local user_home
    user_home="$(get-user-home)"
    
    local -a targets=("$user_home")
    
    for root in "${targets[@]}"; do
        if [[ -d "$root" ]]; then
            log-info "Configuring protection for: $root"
            protect-directory-recursive "$root"
        else
            log-warn "Target not found: $root"
        fi
    done
    
    log-success "Folder protection configured"
}

main "$@"
