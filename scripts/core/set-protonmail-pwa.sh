#!/usr/bin/env zsh
# @file set-protonmail-pwa.sh
# @brief Creates ProtonMail PWA desktop entry
# @description
#   Sets up ProtonMail as a Progressive Web App using Brave browser.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly APPS_DIR="/usr/local/share/applications"
readonly ICONS_DIR="/usr/local/share/icons/hicolor/scalable/apps"
readonly ICON_URL="https://cdn.simpleicons.org/protonmail/6D4AFF"

# @description Sets up ProtonMail PWA desktop entry.
setup-protonmail-pwa() {
    ensure-root
    log-info "Setting up ProtonMail PWA"

    mkdir -p "$APPS_DIR"
    mkdir -p "$ICONS_DIR"

    log-info "Downloading ProtonMail icon"
    curl -fsSL -o "$ICONS_DIR/protonmail.svg" "$ICON_URL"

    cat > "$APPS_DIR/protonmail-pwa.desktop" <<EOF
[Desktop Entry]
Name=ProtonMail (PWA)
Exec=brave-browser --app=https://mail.proton.me
Icon=protonmail
Type=Application
Categories=Office;Network;Email;
StartupWMClass=mail.proton.me
EOF

    log-success "ProtonMail PWA configured"
}

# @description Main entry point.
main() {
    setup-protonmail-pwa
}

main "$@"
