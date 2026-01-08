#!/usr/bin/bash
# Optimize System

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly -a SERVICES_TO_DISABLE=(
    "cups.service" "cups-browsed.service"
    "avahi-daemon.service" "avahi-daemon.socket"
    "ModemManager.service"
    "bluetooth.service"
)

readonly -a SERVICES_TO_MASK=(
    "geoclue.service"
    "tracker-miner-fs-3.service"
    "tracker-extract-3.service"
)

disable-services() {
    log-info "Disabling unnecessary services..."
    
    for svc in "${SERVICES_TO_DISABLE[@]}"; do
        if systemctl is-enabled "$svc" &>/dev/null; then
            systemctl disable --now "$svc" 2>/dev/null || true
            log-info "Disabled: $svc"
        fi
    done
    
    for svc in "${SERVICES_TO_MASK[@]}"; do
        systemctl mask "$svc" 2>/dev/null || true
        log-info "Masked: $svc"
    done
    
    log-success "Services optimized"
}

configure-sysctl() {
    log-info "Applying kernel optimizations..."
    
    local sysctl_file="/etc/sysctl.d/99-performance.conf"
    
    cat > "$sysctl_file" <<'EOF'
# Swappiness (prefer RAM over swap)
vm.swappiness=10

# VFS cache pressure
vm.vfs_cache_pressure=50

# Dirty ratio (delay writes for better throughput)
vm.dirty_ratio=15
vm.dirty_background_ratio=5

# Network optimizations
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_fastopen=3

# Disable IPv6 if not needed (optional)
# net.ipv6.conf.all.disable_ipv6=1
EOF

    sysctl --system &>/dev/null
    log-success "Kernel parameters applied"
}

configure-tlp() {
    if ! command -v tlp &>/dev/null; then
        log-info "TLP not installed, skipping"
        return
    fi
    
    log-info "Enabling TLP..."
    systemctl enable --now tlp.service 2>/dev/null || true
    systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>/dev/null || true
    log-success "TLP configured"
}

disable-gnome-software-autostart() {
    local autostart_dir="/etc/xdg/autostart"
    local gnome_software="$autostart_dir/org.gnome.Software.desktop"
    
    if [[ -f "$gnome_software" ]]; then
        log-info "Disabling GNOME Software autostart..."
        echo "Hidden=true" >> "$gnome_software" 2>/dev/null || true
    fi
}

main() {
    ensure-root
    
    disable-services
    configure-sysctl
    configure-tlp
    disable-gnome-software-autostart
    
    log-success "System optimized"
}

main "$@"
