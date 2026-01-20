#!/usr/bin/env zsh
# @file index.sh
# @brief Fedora Atomic Manager interactive menu
# @description
#   Provides an interactive menu for system management tasks
#   on Fedora Atomic variants.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"

source "$SCRIPT_DIR/lib/common.sh"

# @description Displays the main menu.
show-menu() {
    local distro
    distro="$(detect-distro)"

    printf "${BOLD}${BLUE}***************************${NC}\n"
    printf "${BOLD}  FEDORA ATOMIC MANAGER${NC}\n"
    printf "     Flavour: ${BLUE}%s${NC}\n" "$distro"
    printf "${BOLD}${BLUE}***************************${NC}\n"
    printf "\n"
    printf "  [1] Optimize System\n"
    printf "  [2] Update System\n"
    printf "  [3] Delete Folder\n"
    printf "  [4] Folder Protection\n"
    printf "  [5] Switch Distro\n"
    printf "  [6] Deep Clean\n"
    printf "  [7] Install IDEs\n"
    printf "  [8] ${RED}Exit${NC}\n"
    printf "\n"
}

# @description Main entry point.
main() {
    chmod +x "$SCRIPT_DIR/scripts/configure.sh" \
             "$SCRIPT_DIR/scripts/core/"*.sh \
             "$SCRIPT_DIR/scripts/distro/kionite/"*.sh \
             "$SCRIPT_DIR/scripts/distro/silverblue/"*.sh \
             "$SCRIPT_DIR/scripts/utils/"*.sh \
             "$SCRIPT_DIR/scripts/utils/folder-protection/"*.sh \
             "$SCRIPT_DIR/lib/"*.sh 2>/dev/null || true

    while true; do
        clear
        show-menu
        printf "> "
        read -r choice

        case "$choice" in
            1) confirm "Run configuration?" && "$SCRIPT_DIR/scripts/configure.sh" ;;
            2) confirm "Update system?" && "$SCRIPT_DIR/scripts/utils/update-system.sh" ;;
            3) confirm "Delete folder?" && "$SCRIPT_DIR/scripts/utils/delete-folder.sh" ;;
            4) confirm "Toggle folder protection?" && "$SCRIPT_DIR/scripts/utils/folder-protection/main.sh" ;;
            5) confirm "Switch distro?" && "$SCRIPT_DIR/scripts/utils/switch-distro.sh" ;;
            6) confirm "Deep clean home (risk of data loss)?" && "$SCRIPT_DIR/scripts/utils/deep-clean.sh" ;;
            7) confirm "Install IDEs (IntelliJ, CLion, Android Studio)?" && "$SCRIPT_DIR/scripts/utils/install-ides.sh" ;;
            8) log-info "Exiting..."; exit 0 ;;
            *) log-warn "Invalid option: $choice" ;;
        esac

        printf "\n"
        printf "Press Enter to continue..."
        read -k 1 -r
    done
}

main "$@"
