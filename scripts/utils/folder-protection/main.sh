#!/usr/bin/env zsh
# @file main.sh
# @brief Toggles folder protection state
# @description
#   Checks current protection state and toggles it.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

readonly ANCHOR_FILE=".state_protected"

# @description Main entry point.
main() {
    ensure-root

    local user_home anchor_path
    user_home="$(get-user-home)"
    anchor_path="$user_home/$ANCHOR_FILE"

    if [[ -f "$anchor_path" ]]; then
        log-info "Protection is currently: ACTIVE. Disabling..."
        "$SCRIPT_DIR/unset.sh"
    else
        log-info "Protection is currently: INACTIVE. Enabling..."
        "$SCRIPT_DIR/set.sh"
    fi
}

main "$@"
