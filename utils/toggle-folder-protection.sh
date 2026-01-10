#!/usr/bin/env zsh
# =============================================================================
# Toggle Folder Protection
# Toggles the state of folder protection
# =============================================================================

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../lib/common.sh"

# =============================================================================
# Constants
# =============================================================================

readonly ANCHOR_FILE=".state_protected"

# =============================================================================
# Entry Point
# =============================================================================

main() {
    ensure-root
    
    local user_home
    user_home="$(get-user-home)"
    local anchor_path="$user_home/$ANCHOR_FILE"
    
    if [[ -f "$anchor_path" ]]; then
        log-info "Protection is currently: ACTIVE. Disabling..."
        "$SCRIPT_DIR/unset-folder-protection.sh"
    else
        log-info "Protection is currently: INACTIVE. Enabling..."
        "$SCRIPT_DIR/set-folder-protection.sh"
    fi
}

main "$@"