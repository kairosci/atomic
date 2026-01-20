#!/usr/bin/env zsh
# @file set.sh
# @brief Enables folder protection with immutable anchor files
# @description
#   Protects visible folders with immutable .state_protected files
#   while unprotecting hidden paths.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

readonly ANCHOR_FILE=".state_protected"

# @description Recursively protects visible directories.
# @arg $1 string Target directory path
protect-directory-recursive() {
    local target_dir="$1"

    if [[ ! -d "$target_dir" ]]; then
        log-warn "Skipping missing directory: $target_dir"
        return 0
    fi

    log-info "Scanning $target_dir recursively"

    find "$target_dir" -mount -type d | while read -r dir; do
        if [[ "$dir" == */.*  ]]; then
            if [[ -f "$dir/$ANCHOR_FILE" ]]; then
                log-info "Unprotecting: $dir"
                chattr -i "$dir/$ANCHOR_FILE" 2>/dev/null || true
                rm -f "$dir/$ANCHOR_FILE"
            fi
        else
            if [[ -f "$dir/$ANCHOR_FILE" ]]; then
                continue
            fi

            log-info "Protecting: $dir"
            touch "$dir/$ANCHOR_FILE"
            chattr +i "$dir/$ANCHOR_FILE" 2>/dev/null || log-warn "Failed to protect $dir"
        fi
    done
}

# @description Main entry point.
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
