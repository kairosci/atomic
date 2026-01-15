#!/usr/bin/env zsh
# Fedora Atomic Configuration Index

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../lib/common.sh"

#######################################
# Runs configuration scripts based on the detected distribution.
# Tracks the execution status of each script and prints a summary.
# Globals:
#   SCRIPT_DIR
#   GREEN
#   RED
#   NC
# Arguments:
#   None
#######################################
run-scripts() {
    local distro
    distro="$(detect-distro)"

    log-title "Configuration for $distro"

    local core_dir distro_dir
    core_dir="$(get-core-dir)"
    distro_dir="$(get-distro-dir)"

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
        "$core_dir/set-codium.sh"
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
                "$distro_dir/cosmic/set-appearance.sh"
            )
            ;;
        *)
            log-warn "Unknown distro: $distro, running common scripts only"
            ;;
    esac

    local -A results
    local all_scripts=("${common_scripts[@]}" "${distro_scripts[@]}")

    log-info "Executing scripts..."

    for script in "${all_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            log-info "Processing: $script"
            if "$script"; then
                results["$(basename "$script")"]="SUCCESS"
            else
                results["$(basename "$script")"]="FAILURE"
                log-error "Script failed: $script"
            fi
        else
            log-warn "Script not found: $script"
            results["$(basename "$script")"]="NOT_FOUND"
        fi
    done

    log-title "Execution Status Log"
    local all_success=true

    for script_name in "${(@k)results}"; do
        if [[ "${results[$script_name]}" == "SUCCESS" ]]; then
            printf "${GREEN}[PASS]${NC} %s\n" "$script_name"
        else
            printf "${RED}[FAIL]${NC} %s\n" "$script_name"
            if [[ "${results[$script_name]}" == "FAILURE" ]]; then
                all_success=false
            fi
        fi
    done

    if "$all_success"; then
        log-success "All scripts completed successfully."
    else
        log-error "Some scripts failed. Please check the logs."
    fi
}

#######################################
# Main entry point for the configuration script.
# Arguments:
#   None
#######################################
main() {
    run-scripts
}

main "$@"
