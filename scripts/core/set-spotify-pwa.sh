#!/usr/bin/env zsh
# @file set-spotify-pwa.sh
# @brief Creates Spotify PWA desktop entry
# @description
#   Sets up Spotify as a Progressive Web App using Brave browser.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly APPS_DIR="/usr/local/share/applications"
readonly ICONS_DIR="/usr/local/share/icons/hicolor/512x512/apps"
readonly ICON_URL="https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Spotify_logo_without_text.svg/512px-Spotify_logo_without_text.svg.png"

# @description Sets up Spotify PWA desktop entry.
setup-spotify-pwa() {
    ensure-root
    log-info "Setting up Spotify PWA"

    mkdir -p "$APPS_DIR"
    mkdir -p "$ICONS_DIR"

    log-info "Downloading Spotify icon"
    curl -fsSL -o "$ICONS_DIR/spotify.png" "$ICON_URL"

    cat > "$APPS_DIR/spotify-pwa.desktop" <<EOF
[Desktop Entry]
Name=Spotify (PWA)
Exec=brave-browser --app=https://open.spotify.com
Icon=spotify
Type=Application
Categories=Audio;Music;
StartupWMClass=open.spotify.com
EOF

    log-success "Spotify PWA configured"
}

# @description Main entry point.
main() {
    setup-spotify-pwa
}

main "$@"
