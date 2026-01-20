#!/usr/bin/env zsh

# Set Safe Delete
# Configures rm alias to use gio trash for safe deletion


set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

setup-alias() {
    log-info "Configuring safe delete"

    local user_home
    user_home="$(get-user-home)"

    local zshrc="$user_home/.zshrc"
    local real_user
    real_user="$(get-real-user)"

    if [[ ! -f "$zshrc" ]]; then
        log-error ".zshrc not found: $zshrc"
        return 1
    fi

    if ! command-exists gio; then
        log-warn "'gio' command not found. Cannot configure safe delete."
        return 0
    fi

    if grep -q "Safe Delete Configuration (Kionite Setup)" "$zshrc"; then
        log-info "Safe delete already configured"
        return 0
    fi

    log-info "Adding safe delete aliases to $zshrc"

    {
        echo ""
        echo "# Safe Delete Configuration (Kionite Setup)"
        echo "alias rm='gio trash 2>/dev/null || /usr/bin/rm'"
        echo "alias rp='/usr/bin/rm'"
    } >> "$zshrc"

    fix-ownership "$zshrc"

    log-success "Safe delete configured. Restart terminal or run 'source ~/.zshrc'"
}

main() {
    ensure-root
    setup-alias
}

main "$@"
