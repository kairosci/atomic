#!/usr/bin/env zsh
# *****************************************************************************
# Set Toolbox Dev Container
# Creates a Fedora-based toolbox container for development
# Includes: Node.js, NPM, Build Tools, Zsh
# *****************************************************************************

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

# *****************************************************************************
# Constants
# *****************************************************************************

readonly CONTAINER_NAME="dev"
readonly PACKAGES="nodejs npm @development-tools zsh git curl wget"

# *****************************************************************************
# Main Functions
# *****************************************************************************

check-toolbox() {
    require-command toolbox "toolbox is required to create containers (native in Fedora Silverblue/Kionite)"
}

create-container() {
    log-info "Checking for existing '$CONTAINER_NAME' container..."
    
    if toolbox list | grep -q "$CONTAINER_NAME"; then
        log-warn "Container '$CONTAINER_NAME' already exists."
        read -r -p "Do you want to recreate it? [y/N] " response
        if [[ "$response" =~ ^[yY]$ ]]; then
            log-info "Stopping and removing existing container..."
            # Toolbox doesn't have a 'stop' command in the same way, but we can remove it.
            # Usually podman stop is used if needed, but toolbox rm -f works.
            toolbox rm -f "$CONTAINER_NAME" || log-warn "Failed to remove existing container"
        else
            log-info "Skipping creation."
            return 0
        fi
    fi

    log-info "Creating toolbox container '$CONTAINER_NAME'..."
    # Toolbox creates a container based on the current system or fedora-toolbox image
    toolbox create -y -n "$CONTAINER_NAME"

    log-info "Installing packages: $PACKAGES"
    # Install packages inside the toolbox
    # We use 'toolbox run' to execute dnf inside the container
    toolbox run -n "$CONTAINER_NAME" sudo dnf install -y ${(z)PACKAGES}

    log-success "Container '$CONTAINER_NAME' created and configured successfully."
}

configure-tips() {
    log-info "Note: Toolbox shares your \$HOME, so your Host configuration files are available."
    log-info "To enter the container: toolbox enter $CONTAINER_NAME"
}

# *****************************************************************************
# Entry Point
# *****************************************************************************

main() {
    log-title "Setting up '$CONTAINER_NAME' Toolbox Environment"
    
    check-toolbox
    create-container
    configure-tips
    
    log-success "Setup complete!"
    echo -e "Enter the container with: ${BOLD}toolbox enter $CONTAINER_NAME${NC}"
}

main "$@"
