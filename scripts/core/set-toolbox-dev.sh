#!/usr/bin/env zsh
# Set Toolbox Dev Container
# Creates a Fedora-based toolbox container for development
# Includes: Node.js, NPM, Build Tools, Zsh, VSCode, Chromium

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly CONTAINER_NAME="dev"
readonly PACKAGES="nodejs npm @development-tools zsh git curl wget libXext libXrender libXtst libXi freetype jq code chromium gh"


check-toolbox() {
    require-command toolbox "toolbox is required to create containers (native in Fedora Silverblue/Kionite)"
}

create-or-update-container() {
    log-info "Checking for existing '$CONTAINER_NAME' container..."

    if toolbox list | grep -q "$CONTAINER_NAME"; then
        log-info "Container '$CONTAINER_NAME' already exists. Updating packages..."
    else
        log-info "Creating toolbox container '$CONTAINER_NAME'..."
        toolbox create -y -c "$CONTAINER_NAME"
    fi

    log-info "Installing/Updating packages: $PACKAGES"
    # Add VSCode repository
    toolbox run -c "$CONTAINER_NAME" sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    toolbox run -c "$CONTAINER_NAME" sudo bash -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null'
    # dnf install -y will skip already installed packages and install missing ones
    toolbox run -c "$CONTAINER_NAME" sudo dnf install -y ${(z)PACKAGES}

    log-success "Container '$CONTAINER_NAME' configured successfully."
}

install-vscode() {
    log-info "Installing VSCode extensions..."

    # Read extensions from config file
    local extensions_file="$SCRIPT_DIR/../../config/vscode/extensions.txt"
    if [[ ! -f "$extensions_file" ]]; then
        log-error "Extensions file not found: $extensions_file"
        return 1
    fi

    local -a extensions
    extensions=("${(@f)$(<"$extensions_file")}") # Read into array splitting by line

    for ext in "${extensions[@]}"; do
        # Skip empty lines
        [[ -z "$ext" ]] && continue
        toolbox run -c "$CONTAINER_NAME" code --install-extension "$ext" --force
    done

    # Configure VSCode settings
    log-info "Configuring VSCode settings..."
    toolbox run -c "$CONTAINER_NAME" mkdir -p ~/.vscode

    local settings_file="$SCRIPT_DIR/../../config/vscode/settings.json"
    if [[ -f "$settings_file" ]]; then
         # We need to copy the file into the container.
         # Since toolbox shares home, we can copy to the destination directly if it's in the home dir.
         # But the destination ~/.vscode/settings.json IS in the home dir.
         # So we can just cp it.
         cp -f "$settings_file" "$HOME/.vscode/settings.json"
         log-success "VSCode settings updated from $settings_file"
    else
        log-warn "Settings file not found: $settings_file"
    fi
}

set-browser-default() {
    log-info "Setting Chromium as default browser..."

    toolbox run -c "$CONTAINER_NAME" bash -c "
#!/usr/bin/env bash
xdg-settings set default-web-browser chromium-browser.desktop
xdg-mime default chromium-browser.desktop x-scheme-handler/http
xdg-mime default chromium-browser.desktop x-scheme-handler/https
echo 'Chromium impostato come browser di default.'
"
}

set-os-theme-default() {
    log-info "Setting OS theme to default and removing flavour themes..."

    # Set GTK theme to Adwaita
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'

    # Remove Papirus icon theme if installed
    sudo dnf remove -y papirus-icon-theme* || true

    log-success "OS theme set to default."
}

configure-aliases() {
    log-info "Configuring aliases in host .zshrc..."
    local user_home
    user_home="$(get-user-home)"
    local zshrc="$user_home/.zshrc"

    # Define aliases map
    local -A aliases
    aliases=(
        "code" "toolbox run -c $CONTAINER_NAME code"
        "chromium" "toolbox run -c $CONTAINER_NAME chromium"
        "gh" "toolbox run -c $CONTAINER_NAME gh"
        "node" "toolbox run -c $CONTAINER_NAME node"
        "npm" "toolbox run -c $CONTAINER_NAME npm"
        "npx" "toolbox run -c $CONTAINER_NAME npx"
    )

    if [[ -f "$zshrc" ]]; then
        if ! grep -Fq "# Toolbox Aliases" "$zshrc"; then
            echo "" >> "$zshrc"
            echo "# Toolbox Aliases" >> "$zshrc"
        fi

        for cmd in "${(@k)aliases}"; do
            local alias_def="alias $cmd='${aliases[$cmd]}'"
            if ! grep -Fq "alias $cmd=" "$zshrc"; then
                echo "$alias_def" >> "$zshrc"
                log-success "Alias '$cmd' added"
            else
                log-info "Alias '$cmd' already exists"
            fi
        done
    else
        log-warn ".zshrc not found, skipping alias configuration"
    fi
}

configure-tips() {
    log-info "Note: Toolbox shares your \$HOME, so your Host configuration files are available."
    log-info "To enter the container: toolbox enter -c $CONTAINER_NAME"
    log-info "To run VSCode: toolbox run -c $CONTAINER_NAME code"
    log-info "To run Chromium: toolbox run -c $CONTAINER_NAME chromium"
    log-info "To run GitHub CLI: toolbox run -c $CONTAINER_NAME gh"
}

main() {
    log-title "Setting up '$CONTAINER_NAME' Toolbox Environment"

    check-toolbox
    create-or-update-container
    install-vscode
    set-browser-default
    configure-aliases
    configure-tips
    set-os-theme-default

    log-success "Setup complete!"
    echo -e "Enter the container with: ${BOLD}toolbox enter -c $CONTAINER_NAME${NC}"
}

main "$@"
