#!/usr/bin/env zsh
# @file install-ides.sh
# @brief Installs JetBrains IDEs and Android Studio
# @description
#   Downloads and installs IntelliJ IDEA, CLion, and Android Studio
#   to /opt with version symlinks and shell aliases.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly INSTALL_DIR="/opt"
readonly API_URL="https://data.services.jetbrains.com/products/releases"

# @description Extracts a value from JSON using Python.
# @arg $1 string JSON query path
# @stdout Extracted value
get_json_value() {
    local query="$1"
    python3 -c "import sys, json; data=json.load(sys.stdin); print(data$query)" 2>/dev/null || echo ""
}

# @description Sets up a shell alias in .zshrc.
# @arg $1 string Alias name
# @arg $2 string Script path
setup_alias() {
    local alias_name="$1"
    local script_path="$2"
    local user_home zshrc
    user_home="$(get-user-home)"
    zshrc="$user_home/.zshrc"

    if [[ ! -f "$zshrc" ]]; then
        log-warn "$zshrc not found, skipping alias creation"
        return
    fi

    if ! grep -q "alias $alias_name=" "$zshrc"; then
        echo "" >> "$zshrc"
        echo "alias $alias_name='$script_path'" >> "$zshrc"
        log-success "Alias '$alias_name' added to .zshrc"
        fix-ownership "$zshrc"
    else
        sed -i "s|alias $alias_name=.*|alias $alias_name='$script_path'|" "$zshrc"
        log-info "Alias '$alias_name' updated"
    fi
}

# @description Removes a shell alias from .zshrc.
# @arg $1 string Alias name
remove_alias() {
    local alias_name="$1"
    local user_home zshrc
    user_home="$(get-user-home)"
    zshrc="$user_home/.zshrc"

    if [[ ! -f "$zshrc" ]]; then
        return
    fi

    if grep -q "alias $alias_name=" "$zshrc"; then
         sed -i "/alias $alias_name=/d" "$zshrc"
         log-success "Alias '$alias_name' removed from .zshrc"
         fix-ownership "$zshrc"
    fi
}

# @description Installs a JetBrains IDE.
# @arg $1 string Product code (IIU, CL, etc.)
# @arg $2 string Product name
# @arg $3 string Binary name
install_jetbrains() {
    local code="$1"
    local name="$2"
    local binary_name="$3"

    log-info "Checking updates for $name ($code)..."

    local json version download_url target_dir current_link
    json=$(curl -s "$API_URL?code=$code&latest=true&type=release")
    version=$(echo "$json" | get_json_value "['$code'][0]['version']")
    download_url=$(echo "$json" | get_json_value "['$code'][0]['downloads']['linux']['link']")

    if [[ -z "$version" ]]; then
        log-error "Could not find version for $name"
        return 1
    fi

    target_dir="$INSTALL_DIR/$name-$version"
    current_link="$INSTALL_DIR/$name"

    if [[ -d "$target_dir" ]]; then
        log-info "$name $version is already installed."
    else
        log-info "Installing $name $version..."

        local temp_file tar_content extracted_path
        temp_file=$(mktemp)

        log-info "Downloading $download_url..."
        curl -L -o "$temp_file" "$download_url"

        log-info "Extracting to $INSTALL_DIR..."
        tar_content=$(tar -tf "$temp_file" | head -1 | cut -f1 -d"/")

        sudo tar -xzf "$temp_file" -C "$INSTALL_DIR"
        rm "$temp_file"

        extracted_path="$INSTALL_DIR/$tar_content"

        if [[ -d "$extracted_path" && "$extracted_path" != "$target_dir" ]]; then
            sudo mv "$extracted_path" "$target_dir"
        fi

        log-success "$name $version installed at $target_dir"
    fi

    if [[ -L "$current_link" ]]; then
        sudo rm "$current_link"
    fi
    sudo ln -s "$target_dir" "$current_link"

    setup_alias "$binary_name" "$current_link/bin/$binary_name.sh"
}

# @description Installs Android Studio.
install_android_studio() {
    log-info "Checking updates for Android Studio..."

    local page_content download_url version target_dir current_link
    page_content=$(curl -s "https://developer.android.com/studio")
    download_url=$(echo "$page_content" | grep -oP 'https://redirector.gvt1.com/edgedl/android/studio/ide-zips/[0-9.]+/android-studio-[0-9.]+-linux.tar.gz' | head -n 1)

    if [[ -z "$download_url" ]]; then
        log-warn "Could not find Android Studio download URL automatically."
        return
    fi

    version=$(echo "$download_url" | grep -oP 'android-studio-\K[0-9.]+(?=-linux)')
    target_dir="$INSTALL_DIR/android-studio-$version"
    current_link="$INSTALL_DIR/android-studio"

    if [[ -d "$target_dir" ]]; then
        log-info "Android Studio $version is already installed."
    else
        log-info "Installing Android Studio $version..."
        local temp_file raw_dir
        temp_file=$(mktemp)

        log-info "Downloading $download_url..."
        curl -L -o "$temp_file" "$download_url"

        log-info "Extracting..."
        sudo tar -xzf "$temp_file" -C "$INSTALL_DIR"
        rm "$temp_file"

        raw_dir="$INSTALL_DIR/android-studio"
        if [[ -d "$raw_dir" ]]; then
            sudo mv "$raw_dir" "$target_dir"
        fi

        log-success "Android Studio $version installed"
    fi

    if [[ -L "$current_link" ]]; then
        sudo rm "$current_link"
    fi
    sudo ln -s "$target_dir" "$current_link"

    setup_alias "studio" "$current_link/bin/studio.sh"
}

# @description Uninstalls a JetBrains IDE.
# @arg $1 string Product code (ignored, kept for symmetry)
# @arg $2 string Product name
# @arg $3 string Binary name
uninstall_jetbrains() {
    local name="$2"
    local binary_name="$3"
    local current_link="$INSTALL_DIR/$name"

    if [[ -L "$current_link" ]]; then
        local target_dir
        target_dir=$(readlink -f "$current_link")
        log-info "Removing $name from $target_dir..."

        sudo rm "$current_link"
        if [[ -d "$target_dir" ]]; then
            sudo rm -rf "$target_dir"
        fi

        remove_alias "$binary_name"
        log-success "$name uninstalled"
    elif [[ -d "$INSTALL_DIR/$name" ]]; then
        # Handle case where it might be a directory instead of symlink (older installs?)
        log-info "Removing $name directory..."
        sudo rm -rf "$INSTALL_DIR/$name"
        remove_alias "$binary_name"
        log-success "$name uninstalled"
    fi
}

# @description Uninstalls Android Studio.
uninstall_android_studio() {
    local name="android-studio"
    local binary_name="studio"
    local current_link="$INSTALL_DIR/$name"

    if [[ -L "$current_link" ]]; then
        local target_dir
        target_dir=$(readlink -f "$current_link")
        log-info "Removing $name from $target_dir..."

        sudo rm "$current_link"
        if [[ -d "$target_dir" ]]; then
            sudo rm -rf "$target_dir"
        fi

        remove_alias "$binary_name"
        log-success "$name uninstalled"
    elif [[ -d "$INSTALL_DIR/$name" ]]; then
        log-info "Removing $name directory..."
        sudo rm -rf "$INSTALL_DIR/$name"
        remove_alias "$binary_name"
        log-success "$name uninstalled"
    fi
}

# @description Checks if any IDEs are installed.
is_any_installed() {
    if [[ -L "$INSTALL_DIR/intellij" ]] || [[ -L "$INSTALL_DIR/clion" ]] || [[ -L "$INSTALL_DIR/android-studio" ]]; then
        return 0
    fi
    return 1
}

# @description Main entry point.
main() {
    ensure-root

    if is_any_installed; then
        log-info "IDEs detected. Toggling to UNINSTALL mode."
        uninstall_jetbrains "IIU" "intellij" "idea"
        uninstall_jetbrains "CL" "clion" "clion"
        uninstall_android_studio
    else
        log-info "No IDEs detected. Toggling to INSTALL mode."
        install_jetbrains "IIU" "intellij" "idea"
        install_jetbrains "CL" "clion" "clion"
        install_android_studio
    fi
}

main "$@"
