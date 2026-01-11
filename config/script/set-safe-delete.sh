#!/usr/bin/env zsh
# *****************************************************************************
# Set Safe Delete
# Configures rm alias to use gio trash for safe deletion
# *****************************************************************************

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

# *****************************************************************************
# Main Function
# *****************************************************************************

setup-alias() {
    log-info "Configuring safe delete"
    
    local user_home
    user_home="$(get-user-home)"
    
    local bashrc="$user_home/.bashrc"
    local real_user
    real_user="$(get-real-user)"
    
    if [[ ! -f "$bashrc" ]]; then
        log-error ".bashrc not found: $bashrc"
        return 1
    fi
    
    if ! command-exists gio; then
        log-warn "'gio' command not found. Cannot configure safe delete."
        return 0
    fi
    
    if grep -q "Safe Delete Configuration (Kionite Setup)" "$bashrc"; then
        log-info "Safe delete already configured"
        return 0
    fi
    
    log-info "Adding safe delete aliases to $bashrc"
    
    {
        echo ""
        echo "# Safe Delete Configuration (Kionite Setup)"
        echo "alias rm='gio trash 2>/dev/null || /usr/bin/rm'"
        echo "alias rmp='/usr/bin/rm'"
    } >> "$bashrc"
    
    fix-ownership "$bashrc"
    
    log-success "Safe delete configured. Restart terminal or run 'source ~/.bashrc'"
}

# *****************************************************************************
# Entry Point
# *****************************************************************************

main() {
    ensure-root
    setup-alias
}

main "$@"
