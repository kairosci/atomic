#!/usr/bin/bash
# Fedora Atomic Manager

set -euo pipefail

TARGET_FILE="${BASH_SOURCE[0]}"
[[ -L "$TARGET_FILE" ]] && TARGET_FILE="$(readlink -f "$TARGET_FILE")"
readonly SCRIPT_DIR="$(cd "$(dirname "$TARGET_FILE")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"

show-menu() {
    local distro
    distro="$(detect-distro)"
    
    clear
    echo "================================"
    echo "    Fedora Atomic Manager"
    echo "       [$distro]"
    echo "================================"
    echo ""
    echo "  1. Optimize System"
    echo "  2. Update System"
    echo "  3. Delete Folder"
    echo "  4. Enable/Disable Folder Protection"
    echo "  5. Switch Distro (Kionite/Silverblue)"
    echo "  6. Exit"
    echo ""
}

main() {
    chmod +x "$SCRIPT_DIR/config/index.sh" \
             "$SCRIPT_DIR/config/script/"*.sh \
             "$SCRIPT_DIR/config/script/kionite/"*.sh \
             "$SCRIPT_DIR/config/script/silverblue/"*.sh \
             "$SCRIPT_DIR/utils/"*.sh \
             "$SCRIPT_DIR/lib/"*.sh 2>/dev/null || true
    
    while true; do
        show-menu
        read -rp "> " choice
        
        clear
        case "$choice" in
            1) "$SCRIPT_DIR/config/index.sh" ;;
            2) "$SCRIPT_DIR/utils/update-system.sh" ;;
            3) "$SCRIPT_DIR/utils/delete-folder.sh" ;;
            4) "$SCRIPT_DIR/utils/toggle-folder-protection.sh" ;;
            5) "$SCRIPT_DIR/utils/switch-distro.sh" ;;
            6) log-info "Goodbye!"; exit 0 ;;
            *) log-warn "Invalid option: $choice" ;;
        esac
        
        echo ""
        read -rp "Press Enter to continue..."
    done
}

main "$@"
