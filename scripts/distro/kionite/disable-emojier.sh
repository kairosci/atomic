#!/usr/bin/env zsh
# @file disable-emojier.sh
# @brief Hides the KDE Plasma emoji selector
# @description
#   Creates a local desktop override to hide plasma-emojier.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

# @description Disables plasma-emojier via local desktop override.
disable-plasma-emojier() {
    log-info "Disabling plasma-emojier"

    local user_home apps_dir desktop_file
    user_home="$(get-user-home)"
    apps_dir="$user_home/.local/share/applications"
    desktop_file="$apps_dir/org.kde.plasma.emojier.desktop"

    mkdir -p "$apps_dir"

    if [[ ! -f "$desktop_file" ]]; then
        cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=Emoji Selector
Hidden=true
NoDisplay=true
EOF
        fix-ownership "$desktop_file"
        log-success "Emojier hidden"
    else
        log-info "Emojier already hidden"
    fi
}

# @description Main entry point.
main() {
    disable-plasma-emojier
}

main "$@"
