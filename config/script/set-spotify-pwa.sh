#!/usr/bin/env zsh
# =============================================================================
# Set Spotify PWA
# Creates a desktop entry for Spotify as a Progressive Web App via Brave
# =============================================================================

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# Constants
# =============================================================================

readonly APPS_DIR="/usr/local/share/applications"
readonly ICONS_DIR="/usr/local/share/icons/hicolor/512x512/apps"
readonly ICON_URL="https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Spotify_logo_without_text.svg/512px-Spotify_logo_without_text.svg.png"

# =============================================================================
# Main Function
# =============================================================================

setup-spotify-pwa() {
    ensure-root
    log-info "Setting up Spotify PWA"
    
    # Create directories
    mkdir -p "$APPS_DIR"
    mkdir -p "$ICONS_DIR"
    
    # Download icon
    log-info "Downloading Spotify icon"
    curl -fsSL -o "$ICONS_DIR/spotify.png" "$ICON_URL"
    
    # Create desktop entry
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

# =============================================================================
# Entry Point
# =============================================================================

main() {
    setup-spotify-pwa
}

main "$@"
