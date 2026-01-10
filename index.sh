#!/usr/bin/env zsh
# Fedora Atomic Manager

set -euo pipefail

TARGET_FILE="${BASH_SOURCE[0]}"
[[ -L "$TARGET_FILE" ]] && TARGET_FILE="$(readlink -f "$TARGET_FILE")"
readonly SCRIPT_DIR="$(cd "$(dirname "$TARGET_FILE")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"

show-menu() {
    local distro
    distro="$(detect-distro)"
    
    printf "${BOLD}${BLUE}***************************${NC}\n"
    printf "${BOLD}     FEDORA ATOMIC MANAGER${NC}\n"
    printf "        Flavour: ${BLUE}%s${NC}\n" "$distro"
    printf "${BOLD}${BLUE}***************************${NC}\n"
    printf "\n"
    printf "  [1] Optimize System\n"
    printf "  [2] Update System\n"
    printf "  [3] Delete Folder\n"
    printf "  [4] Folder Protection\n"
    printf "  [5] Switch Distro\n"
    printf "  [6] ${RED}Exit${NC}\n"
    printf "\n"
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
            6) log-info "Exiting..."; exit 0 ;;
            *) log-warn "Invalid option: $choice" ;;
        esac
        
        printf "\n"
        read -rp "Press Enter to continue..."
    done
}

main "$@"
