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

    # List of extensions to install
    local extensions=(
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
        toolbox run -c "$CONTAINER_NAME" code --install-extension "$ext" --force
    done

    # Configure VSCode settings
    log-info "Configuring VSCode settings..."
    toolbox run -c "$CONTAINER_NAME" mkdir -p ~/.vscode
    toolbox run -c "$CONTAINER_NAME" bash -c 'cat > ~/.vscode/settings.json <<EOF
{
    "editor.fontFamily": "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
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

    log-success "VSCode extensions and settings configured."
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
