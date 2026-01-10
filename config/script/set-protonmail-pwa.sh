#!/usr/bin/env zsh
# =============================================================================
# Set ProtonMail PWA
# Creates a desktop entry for ProtonMail as a Progressive Web App via Brave
# =============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# Constants
# =============================================================================

readonly APPS_DIR="/usr/local/share/applications"
readonly ICONS_DIR="/usr/local/share/icons/hicolor/scalable/apps"
readonly ICON_URL="https://cdn.simpleicons.org/protonmail/6D4AFF"

# =============================================================================
# Main Function
# =============================================================================

setup-protonmail-pwa() {
    ensure-root
    log-info "Setting up ProtonMail PWA"
    
    # Create directories
    mkdir -p "$APPS_DIR"
    mkdir -p "$ICONS_DIR"
    
    # Download icon
    log-info "Downloading ProtonMail icon"
    curl -fsSL -o "$ICONS_DIR/protonmail.svg" "$ICON_URL"
    
    # Create desktop entry
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

# =============================================================================
# Entry Point
# =============================================================================

main() {
    setup-protonmail-pwa
}

main "$@"
