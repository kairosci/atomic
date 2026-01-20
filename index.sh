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
    
    echo -e "${BOLD}${BLUE}--------------------------------${NC}"
    echo -e "${BOLD}     FEDORA ATOMIC MANAGER${NC}"
    echo -e "        Mode: ${BLUE}$distro${NC}"
    echo -e "${BOLD}${BLUE}--------------------------------${NC}"
    echo ""
    echo -e "  [1] Optimize System"
    echo -e "  [2] Update System"
    echo -e "  [3] Delete Folder"
    echo -e "  [4] Folder Protection"
    echo -e "  [5] Switch Distro"
    echo -e "  [6] ${RED}Exit${NC}"
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
            1) confirm "Run configuration?" && "$SCRIPT_DIR/config/index.sh" ;;
            2) confirm "Update system?" && "$SCRIPT_DIR/utils/update-system.sh" ;;
            3) confirm "Delete folder?" && "$SCRIPT_DIR/utils/delete-folder.sh" ;;
            4) confirm "Toggle folder protection?" && "$SCRIPT_DIR/utils/toggle-folder-protection.sh" ;;
            5) confirm "Switch distro?" && "$SCRIPT_DIR/utils/switch-distro.sh" ;;
            6) log-info "Goodbye!"; exit 0 ;;
            *) log-warn "Invalid option: $choice" ;;
        esac
        
        echo ""
        read -rp "Press Enter to continue..."
    done
}

main "$@"
