#!/usr/bin/env zsh
# Fedora Atomic Configuration Index

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../lib/common.sh"

run-scripts() {
    local distro
    distro="$(detect-distro)"

    log-title "Configuration for $distro"

    local core_dir="$SCRIPT_DIR/core"
    local distro_dir="$SCRIPT_DIR/distro"

    [[ -d "$core_dir" ]] || { log-error "Core script directory not found: $core_dir"; exit 1; }

    local -a common_scripts=(
        "$core_dir/hide-grub.sh"
        "$core_dir/rename-btrfs.sh"
        "$core_dir/set-flatpak.sh"
        "$core_dir/set-rpm.sh"
        "$core_dir/set-spotify-pwa.sh"
        "$core_dir/set-protonmail-pwa.sh"
        "$core_dir/manage-system.sh"
        "$core_dir/set-safe-delete.sh"
        "$core_dir/set-omz.sh"
        "$core_dir/optimize-system.sh"
    )

    local -a distro_scripts=()

    case "$distro" in
        kionite)
            distro_scripts=(
                "$distro_dir/kionite/disable-emojier.sh"
                "$distro_dir/kionite/set-launcher-icon.sh"
                "$distro_dir/kionite/set-konsole.sh"
                "$distro_dir/kionite/set-papirus-look.sh"
                "$distro_dir/kionite/optimize-animations.sh"
            )
            ;;
        silverblue)
            distro_scripts=(
                "$distro_dir/silverblue/set-theme.sh"
                "$distro_dir/silverblue/set-extensions.sh"
                "$distro_dir/silverblue/optimize-animations.sh"
            )
            ;;
        cosmic)
            # Cosmic uses standard scripts for now, but we can add specific ones here later
            distro_scripts=(
                "$distro_dir/cosmic/set-appearance.sh" # Placeholder/Future implementation
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
