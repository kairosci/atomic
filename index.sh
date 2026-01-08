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
    
    echo -e "${BOLD}${BLUE}================================${NC}"
    echo -e "${BOLD}    Fedora Atomic Manager${NC}"
    echo -e "       [${BLUE}$distro${NC}]"
    echo -e "${BOLD}${BLUE}================================${NC}"
    echo ""
    echo -e "  ${BLUE}1.${NC} Optimize System"
    echo -e "  ${BLUE}2.${NC} Update System"
    echo -e "  ${BLUE}3.${NC} Delete Folder"
    echo -e "  ${BLUE}4.${NC} Enable/Disable Folder Protection"
    echo -e "  ${BLUE}5.${NC} Switch Distro (Kionite/Silverblue)"
    echo -e "  ${RED}6.${NC} Exit"
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
        clear
        show-menu
        read -rp "> " choice
        
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
