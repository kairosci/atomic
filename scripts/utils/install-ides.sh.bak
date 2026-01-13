#!/usr/bin/env zsh
# Install IDEs (IntelliJ, CLion, Android Studio)

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly INSTALL_DIR="/opt"
readonly API_URL="https://data.services.jetbrains.com/products/releases"


get_json_value() {
    local query="$1"
    python3 -c "import sys, json; data=json.load(sys.stdin); print(data$query)" 2>/dev/null || echo ""
}


setup_alias() {
    local alias_name="$1"
    local script_path="$2"
    local user_home
    user_home="$(get-user-home)"
    local zshrc="$user_home/.zshrc"

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
        # Update existing alias if path changed
        sed -i "s|alias $alias_name=.*|alias $alias_name='$script_path'|" "$zshrc"
        log-info "Alias '$alias_name' updated"
    fi
}


install_jetbrains() {
    local code="$1"
    local name="$2"
    local binary_name="$3"

    log-info "Checking updates for $name ($code)..."

    local json
    json=$(curl -s "$API_URL?code=$code&latest=true&type=release")

    local version
    version=$(echo "$json" | get_json_value "['$code'][0]['version']")
    local download_url
    download_url=$(echo "$json" | get_json_value "['$code'][0]['downloads']['linux']['link']")

    if [[ -z "$version" ]]; then
        log-error "Could not find version for $name"
        return 1
    fi

    local target_dir="$INSTALL_DIR/$name-$version"
    local current_link="$INSTALL_DIR/$name"

    if [[ -d "$target_dir" ]]; then
        log-info "$name $version is already installed."
    else
        log-info "Installing $name $version..."

        local temp_file
        temp_file=$(mktemp)

        log-info "Downloading $download_url..."
        curl -L -o "$temp_file" "$download_url"

        log-info "Extracting to $INSTALL_DIR..."
        # Extract and find the directory name
        local tar_content
        tar_content=$(tar -tf "$temp_file" | head -1 | cut -f1 -d"/")

        sudo tar -xzf "$temp_file" -C "$INSTALL_DIR"
        rm "$temp_file"

        local extracted_path="$INSTALL_DIR/$tar_content"

        if [[ -d "$extracted_path" && "$extracted_path" != "$target_dir" ]]; then
            sudo mv "$extracted_path" "$target_dir"
        fi

        log-success "$name $version installed at $target_dir"
    fi

    # Update symlink
    if [[ -L "$current_link" ]]; then
        sudo rm "$current_link"
    fi
    sudo ln -s "$target_dir" "$current_link"

    # Update alias
    setup_alias "$binary_name" "$current_link/bin/$binary_name.sh"
}


install_android_studio() {
    log-info "Checking updates for Android Studio..."

    # Scraping download page for latest linux tarball
    local page_content
    page_content=$(curl -s "https://developer.android.com/studio")

    local download_url
    download_url=$(echo "$page_content" | grep -oP 'https://redirector.gvt1.com/edgedl/android/studio/ide-zips/[0-9.]+/android-studio-[0-9.]+-linux.tar.gz' | head -n 1)

    if [[ -z "$download_url" ]]; then
        log-warn "Could not find Android Studio download URL automatically."
        return
    fi

    local version
    version=$(echo "$download_url" | grep -oP 'android-studio-\K[0-9.]+(?=-linux)')

    local target_dir="$INSTALL_DIR/android-studio-$version"
    local current_link="$INSTALL_DIR/android-studio"

    if [[ -d "$target_dir" ]]; then
        log-info "Android Studio $version is already installed."
    else
        log-info "Installing Android Studio $version..."
        local temp_file
        temp_file=$(mktemp)

        log-info "Downloading $download_url..."
        curl -L -o "$temp_file" "$download_url"

        log-info "Extracting..."
        sudo tar -xzf "$temp_file" -C "$INSTALL_DIR"
        rm "$temp_file"

        local raw_dir="$INSTALL_DIR/android-studio"
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


main() {
    ensure-root

    # IntelliJ IDEA Ultimate
    install_jetbrains "IIU" "intellij" "idea"

    # CLion
    install_jetbrains "CL" "clion" "clion"

    # Android Studio
    install_android_studio
}


main "$@"
