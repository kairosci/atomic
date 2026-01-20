#!/usr/bin/env zsh
# @file set-toolbox-dev.sh
# @brief Creates a development toolbox container
# @description
#   Sets up a Fedora-based toolbox container with Node.js, NPM,
#   build tools, VSCode, Chromium, and other dev utilities.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly CONTAINER_NAME="dev"
readonly PACKAGES="nodejs npm @development-tools zsh git curl wget libXext libXrender libXtst libXi freetype jq code chromium gh"

# @description Validates toolbox is available.
check-toolbox() {
    require-command toolbox "toolbox is required to create containers (native in Fedora Silverblue/Kionite)"
}

# @description Creates or updates the dev container with packages.
create-or-update-container() {
    log-info "Checking for existing '$CONTAINER_NAME' container..."

    if toolbox list | grep -q "$CONTAINER_NAME"; then
        log-info "Container '$CONTAINER_NAME' already exists. Updating packages..."
    else
        log-info "Creating toolbox container '$CONTAINER_NAME'..."
        toolbox create -y -c "$CONTAINER_NAME"
    fi

    log-info "Installing/Updating packages: $PACKAGES"
    toolbox run -c "$CONTAINER_NAME" sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    toolbox run -c "$CONTAINER_NAME" sudo bash -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null'
    toolbox run -c "$CONTAINER_NAME" sudo dnf install -y ${(z)PACKAGES}

    log-success "Container '$CONTAINER_NAME' configured successfully."
}

# @description Installs VSCode extensions and configures settings.
install-vscode() {
    log-info "Installing VSCode extensions..."

    local -a extensions=(
        "ms-python.python"
        "ms-vscode.vscode-typescript-next"
        "ms-vscode.cpptools"
        "ms-vscode.cmake-tools"
        "llvm-vs-code-extensions.vscode-clangd"
        "golang.go"
        "rust-lang.rust-analyzer"
        "rust-lang.rust"
        "ms-vscode.vscode-java-pack"
        "ms-vscode.vscode-json"
        "ms-vscode.vscode-yaml"
        "ms-vscode.vscode-xml"
        "ms-vscode.vscode-eslint"
        "bradlc.vscode-tailwindcss"
        "esbenp.prettier-vscode"
        "ms-vscode.vscode-css-peek"
        "ms-vscode.vscode-html-css-support"
        "ms-vscode.vscode-css-intellisense"
        "ms-vscode.vscode-js-debug"
        "ms-vscode.vscode-node-debug"
        "ms-vscode.vscode-chrome-debug-core"
        "ms-vscode-remote.remote-containers"
        "ms-vscode.vscode-theme-defaults"
        "ms-vscode.vscode-theme-seti"
        "dracula-theme.theme-dracula"
    )

    for ext in "${extensions[@]}"; do
        # Skip empty lines
        [[ -z "$ext" ]] && continue
        toolbox run -c "$CONTAINER_NAME" code --install-extension "$ext" --force
    done

    log-info "Configuring VSCode settings..."
    toolbox run -c "$CONTAINER_NAME" mkdir -p ~/.vscode
    toolbox run -c "$CONTAINER_NAME" bash -c 'cat > ~/.vscode/settings.json <<EOF
{
    "editor.fontFamily": "system-ui, -apple-system, BlinkMacSystemFont, '\''Segoe UI'\'', Roboto, sans-serif",
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "terminal.integrated.suggest.enabled": true,
    "editor.suggest.showWords": false,
    "editor.suggest.showSnippets": true,
    "editor.suggest.showMethods": true,
    "editor.suggest.showFunctions": true,
    "editor.suggest.showVariables": true,
    "editor.suggest.showModules": true,
    "editor.suggest.showClasses": true,
    "editor.suggest.showInterfaces": true,
    "editor.suggest.showStructs": true,
    "editor.suggest.showEnums": true,
    "editor.suggest.showKeywords": true,
    "editor.suggest.showValues": true,
    "editor.suggest.showConstants": true,
    "editor.suggest.showEnumsMembers": true,
    "editor.suggest.showProperties": true,
    "editor.suggest.showFields": true,
    "editor.suggest.showEvents": true,
    "editor.suggest.showOperators": true,
    "editor.suggest.showUnits": true,
    "editor.suggest.showColors": true,
    "editor.suggest.showFiles": true,
    "editor.suggest.showReferences": true,
    "editor.suggest.showFolders": true,
    "editor.suggest.showTypeParameters": true,
    "editor.suggest.showIssues": true
}
EOF'

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

# @description Sets Chromium as the default browser in the container.
set-browser-default() {
    log-info "Setting Chromium as default browser..."

    toolbox run -c "$CONTAINER_NAME" bash -c "
xdg-settings set default-web-browser chromium-browser.desktop
xdg-mime default chromium-browser.desktop x-scheme-handler/http
xdg-mime default chromium-browser.desktop x-scheme-handler/https
echo 'Chromium set as default browser.'
"
}

# @description Resets host theme to default.
set-os-theme-default() {
    log-info "Setting OS theme to default and removing flavour themes..."

    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
    sudo dnf remove -y papirus-icon-theme* || true

    log-success "OS theme set to default."
}

# @description Configures toolbox aliases in host .zshrc.
configure-aliases() {
    log-info "Configuring aliases in host .zshrc..."

    local user_home zshrc
    user_home="$(get-user-home)"
    zshrc="$user_home/.zshrc"

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

# @description Displays usage tips.
configure-tips() {
    log-info "Note: Toolbox shares your \$HOME, so your Host configuration files are available."
    log-info "To enter the container: toolbox enter -c $CONTAINER_NAME"
    log-info "To run VSCode: toolbox run -c $CONTAINER_NAME code"
    log-info "To run Chromium: toolbox run -c $CONTAINER_NAME chromium"
    log-info "To run GitHub CLI: toolbox run -c $CONTAINER_NAME gh"
}

# @description Main entry point.
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
