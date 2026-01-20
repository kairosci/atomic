#!/usr/bin/env zsh
# @file patch-orchis.sh
# @brief Patches Orchis theme for Kairosci style
# @description
#   Modifies Orchis theme SCSS files to remove border-radius from UI elements.
#   Also creates window decoration CSS overrides with subtle rounding.
#
# @example
#   source patch-orchis.sh
#   patch-border-radius "/path/to/orchis"
#   apply-window-override

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../../lib/common.sh"

# @description Border radius for app UI elements (sharp)
readonly APP_RADIUS="0px"

# @description Border radius for window decorations (subtle)
readonly WINDOW_RADIUS="4px"

# @description Patches all border-radius SCSS variables in Orchis source.
# @arg $1 string Path to cloned Orchis theme directory
# @exitcode 0 Success
# @exitcode 1 Directory not found
patch-border-radius() {
    local orchis_dir="$1"
    local sass_dir="$orchis_dir/src/_sass"

    [[ -d "$orchis_dir" ]] || { log-error "Orchis directory not found: $orchis_dir"; return 1; }
    [[ -d "$sass_dir" ]] || { log-error "SASS directory not found: $sass_dir"; return 1; }

    log-info "Patching border-radius to ${APP_RADIUS}..."

    local -a radius_vars=(
        border-radius material-radius button-radius menu-radius
        menuitem-radius window-radius circular-radius popover-radius
        card-radius dialog-radius tooltip-radius corner-radius
        panel-radius entry-radius switch-radius
    )

    find "$sass_dir" -type f -name "*.scss" | while read -r file; do
        for var in "${radius_vars[@]}"; do
            sed -i -E "s/\\\$${var}:\s*[0-9]+px/\$${var}: ${APP_RADIUS}/g" "$file"
        done
    done

    local -a source_dirs=("$orchis_dir/src/gtk" "$orchis_dir/src/gnome-shell")

    for dir in "${source_dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        find "$dir" -type f \( -name "*.scss" -o -name "*.css" \) -exec \
            sed -i -E "s/border-radius:\s*[0-9]+px/border-radius: ${APP_RADIUS}/g" {} \;
    done

    log-success "Border-radius patched to ${APP_RADIUS}"
}

# @description Creates GTK CSS override files for window decorations.
# @noargs
# @exitcode 0 Success
apply-window-override() {
    log-info "Applying window decoration override..."

    local -a gtk_dirs=("$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0")

    for dir in "${gtk_dirs[@]}"; do
        mkdir -p "$dir"
        cat > "$dir/gtk.css" << 'EOF'
/* Kairosci Style - Subtle window rounding */
window, .window-frame, .csd, decoration { border-radius: 4px; }
.titlebar, headerbar { border-radius: 4px 4px 0 0; }
.dialog-vbox, popover, menu, .menu, tooltip, .tooltip { border-radius: 4px; }
windowcontrols, .titlebutton { border-radius: 2px; }
EOF
        log-info "Created $dir/gtk.css"
    done

    log-success "Window override applied (${WINDOW_RADIUS})"
}
