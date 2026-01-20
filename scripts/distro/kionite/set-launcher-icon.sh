#!/usr/bin/env zsh
# @file set-launcher-icon.sh
# @brief Resets KDE Plasma launcher icon to default
# @description
#   Sets the kickoff launcher icon to the default KDE Plasma icon.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

readonly DEFAULT_ICON="start-here-kde-plasma"

# @description Sets launcher icon to KDE default.
set-launcher-icon() {
    log-info "Setting KDE default launcher icon"

    local user_home config_file applet_id containment_id
    user_home="$(get-user-home)"
    config_file="$user_home/.config/plasma-org.kde.plasma.desktop-appletsrc"

    if [[ ! -f "$config_file" ]]; then
        log-warn "Plasma config not found. Run after first login."
        return 0
    fi

    if ! command-exists kwriteconfig6; then
        log-warn "kwriteconfig6 not found, skipping"
        return 0
    fi

    applet_id="$(grep -B1 "plugin=org.kde.plasma.kickoff" "$config_file" | grep -oP '\[Applets\]\[\K[0-9]+' || true)"
    containment_id="$(grep -B1 "plugin=org.kde.plasma.kickoff" "$config_file" | grep -oP '\[Containments\]\[\K[0-9]+' || true)"

    if [[ -z "$applet_id" ]] || [[ -z "$containment_id" ]]; then
        log-warn "Kickoff applet not found in config"
        return 0
    fi

    kwriteconfig6 --file "$config_file" \
        --group "Containments" --group "$containment_id" \
        --group "Applets" --group "$applet_id" \
        --group "Configuration" --group "General" \
        --key "icon" "$DEFAULT_ICON"

    log-success "Launcher icon set to KDE Plasma default"
    log-info "Restart Plasma or log out/in for changes: kquitapp6 plasmashell && kstart plasmashell"
}

# @description Main entry point.
main() {
    set-launcher-icon
}

main "$@"
