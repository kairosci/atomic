#!/usr/bin/env zsh
# @file toolbox-sync-theme.sh
# @brief Syncs host themes and icons to Toolbox containers
# @description
#   Iterates over all created Toolbox containers and applies
#   the current host theme settings (GTK, Icons, Fonts) via dconf.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly GTK_THEME="Orchis-Dark"
readonly ICON_THEME="Papirus-Dark"
readonly FONT_NAME="Inter Regular 11"
readonly MONO_FONT="Monospace 10"

# @description Syncs theme settings to a specific container.
# @arg $1 string Container name
sync-container() {
    local container="$1"
    log-info "Syncing theme to container: $container"

    # Check if container is running or at least exists
    if ! toolbox list --containers | grep -q "$container"; then
        log-warn "Container $container not found."
        return
    fi

    # Helper to run dconf inside toolbox
    local run_cmd="dconf write /org/gnome/desktop/interface"

    toolbox run --container "$container" dconf write /org/gnome/desktop/interface/gtk-theme "'$GTK_THEME'"
    toolbox run --container "$container" dconf write /org/gnome/desktop/interface/icon-theme "'$ICON_THEME'"
    toolbox run --container "$container" dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"

    # Fonts
    toolbox run --container "$container" dconf write /org/gnome/desktop/interface/font-name "'$FONT_NAME'"
    toolbox run --container "$container" dconf write /org/gnome/desktop/interface/document-font-name "'$FONT_NAME'"
    toolbox run --container "$container" dconf write /org/gnome/desktop/interface/monospace-font-name "'$MONO_FONT'"

    log-success "Synced $container"
}

# @description Main entry point.
main() {
    log-title "Toolbox Theme Sync"

    ensure-user

    if ! command-exists toolbox; then
        log-warn "Toolbox not installed. Skipping sync."
        exit 0
    fi

    # Get list of containers (names only)
    # output format of toolbox list is: CONTAINER ID  CONTAINER NAME  CREATED  STATUS  IMAGE NAME
    # We skip header and get 2nd column
    local containers
    containers=("${(@f)$(toolbox list --containers | tail -n +2 | awk '{print $2}')}")

    if [[ ${#containers[@]} -eq 0 ]]; then
        log-info "No toolbox containers found."
        exit 0
    fi

    for container in "${containers[@]}"; do
        [[ -z "$container" ]] && continue
        sync-container "$container"
    done

    log-success "Toolbox sync completed."
}

main "$@"
