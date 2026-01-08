#!/usr/bin/bash
# Fedora Atomic Configuration Index

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

run-scripts() {
    local distro
    distro="$(detect-distro)"
    
    log-title "Configuration for $distro"
    
    local scripts_dir="$SCRIPT_DIR/script"
    [[ -d "$scripts_dir" ]] || { log-error "Script directory not found: $scripts_dir"; exit 1; }
    
    cd "$scripts_dir"
    
    local -a common_scripts=(
        "./hide-grub.sh"
        "./rename-btrfs.sh"
        "./set-flatpak.sh"
        "./set-rpm.sh"
        "./set-spotify-pwa.sh"
        "./set-protonmail-pwa.sh"
        "./manage-system.sh"
        "./set-safe-delete.sh"
        "./set-omz.sh"
        "./optimize-system.sh"
    )
    
    local -a distro_scripts=()
    
    case "$distro" in
        kionite)
            distro_scripts=(
                "./kionite/disable-emojier.sh"
                "./kionite/set-launcher-icon.sh"
                "./kionite/set-konsole.sh"
                "./kionite/set-papirus-look.sh"
                "./kionite/optimize-animations.sh"
            )
            ;;
        silverblue)
            distro_scripts=(
                "./silverblue/set-papirus.sh"
                "./silverblue/set-extensions.sh"
                "./silverblue/optimize-animations.sh"
            )
            ;;
        *)
            log-warn "Unknown distro: $distro, running common scripts only"
            ;;
    esac
    
    log-info "Executing common scripts..."
    for script in "${common_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            log-info "Processing: $script"
            "$script"
        else
            log-warn "Script not found: $script"
        fi
    done
    
    if [[ ${#distro_scripts[@]} -gt 0 ]]; then
        log-info "Executing $distro-specific scripts..."
        for script in "${distro_scripts[@]}"; do
            if [[ -f "$script" ]]; then
                log-info "Processing: $script"
                "$script"
            else
                log-warn "Script not found: $script"
            fi
        done
    fi
    
    log-success "All configurations applied for $distro"
}

main() {
    run-scripts
}

main "$@"
