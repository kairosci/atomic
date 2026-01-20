#!/usr/bin/env zsh
# @file optimize-system.sh
# @brief System performance optimization
# @description
#   Disables unnecessary services, applies kernel tuning,
#   configures CPU governor, I/O scheduler, and TLP.

set -euo pipefail

readonly SCRIPT_FILE="${0:A}"
readonly SCRIPT_DIR="${SCRIPT_FILE:h}"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly -a SERVICES_TO_DISABLE=(
    "cups.service" "cups-browsed.service"
    "avahi-daemon.service" "avahi-daemon.socket"
    "ModemManager.service"
)

readonly -a SERVICES_TO_MASK=(
    "geoclue.service"
    "tracker-miner-fs-3.service"
    "tracker-extract-3.service"
)

# @description Disables and masks unnecessary services.
disable-services() {
    command-exists systemctl || { log-warn "systemctl not available, skipping service optimization"; return 0; }
    log-info "Disabling unnecessary services..."

    local service_name
    for service_name in "${SERVICES_TO_DISABLE[@]}"; do
        if systemctl is-enabled "$service_name" &>/dev/null; then
            systemctl disable --now "$service_name" 2>/dev/null || log-warn "Failed to disable service: $service_name"
            log-info "Disabled: $service_name"
        fi
    done

    for service_name in "${SERVICES_TO_MASK[@]}"; do
        systemctl mask "$service_name" 2>/dev/null || log-warn "Failed to mask service: $service_name"
        log-info "Masked: $service_name"
    done

    log-success "Services optimized"
}

# @description Applies kernel optimizations via sysctl.
configure-sysctl() {
    log-info "Applying kernel optimizations..."

    local sysctl_config_file="/etc/sysctl.d/99-performance.conf"

    cat > "$sysctl_config_file" <<'EOF'
vm.swappiness=100
vm.vfs_cache_pressure=50
vm.dirty_ratio=15
vm.dirty_background_ratio=5
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=cake
fs.file-max=2097152
EOF

    sysctl --system &>/dev/null
    log-success "Kernel parameters applied"
}

# @description Configures CPU governor to performance mode.
configure-cpu-governor() {
    log-info "Optimizing CPU governor..."

    if command-exists cpupower; then
        cpupower frequency-set -g performance &>/dev/null || log-warn "cpupower failed"
    else
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            if [[ -f "$cpu" ]]; then
                echo "performance" > "$cpu" 2>/dev/null || true
            fi
        done
    fi

    log-success "CPU governor set to performance"
}

# @description Configures I/O scheduler (prefers BFQ).
configure-io-scheduler() {
    log-info "Optimizing I/O scheduler..."

    for dev in /sys/block/sd*(N) /sys/block/nvme*n*(N); do
        if [[ -f "$dev/queue/scheduler" ]]; then
            if grep -q "bfq" "$dev/queue/scheduler"; then
                echo "bfq" > "$dev/queue/scheduler" 2>/dev/null || true
            elif grep -q "mq-deadline" "$dev/queue/scheduler"; then
                echo "mq-deadline" > "$dev/queue/scheduler" 2>/dev/null || true
            fi
        fi
    done

    cat > "/etc/udev/rules.d/60-io-scheduler.rules" <<'EOF'
ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="bfq"
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/scheduler}="bfq"
EOF

    udevadm control --reload 2>/dev/null || true
    log-success "I/O scheduler optimized"
}

# @description Configures TLP for power management.
configure-tlp() {
    if ! command -v tlp &>/dev/null; then
        log-info "TLP not installed, skipping"
        return
    fi

    log-info "Enabling TLP..."
    systemctl enable --now tlp.service 2>/dev/null || log-warn "Failed to enable TLP service"
    systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>/dev/null || log-warn "Failed to mask systemd-rfkill"

    sed -i 's/^CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC="performance"/' /etc/tlp.conf 2>/dev/null || true
    sed -i 's/^CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC="performance"/' /etc/tlp.conf 2>/dev/null || true

    log-success "TLP configured"
}

# @description Disables GNOME Software autostart.
disable-gnome-software-autostart() {
    local autostart_directory="/etc/xdg/autostart"
    local gnome_software_desktop_entry="$autostart_directory/org.gnome.Software.desktop"

    if [[ -f "$gnome_software_desktop_entry" ]]; then
        log-info "Disabling GNOME Software autostart..."
        echo "Hidden=true" >> "$gnome_software_desktop_entry" 2>/dev/null || log-warn "Failed to disable GNOME Software autostart"
    fi
}

# @description Sets up the development toolbox container.
setup-dev-toolbox() {
    log-info "Setting up development toolbox..."

    local toolbox_script="$SCRIPT_DIR/set-toolbox-dev.sh"

    if [[ -f "$toolbox_script" ]]; then
        if [[ -n "${SUDO_USER:-}" ]]; then
            sudo -u "$SUDO_USER" zsh "$toolbox_script" || log-warn "Failed to setup dev toolbox"
        else
            log-warn "SUDO_USER not set, cannot run toolbox setup as non-root user. Skipping."
        fi
    else
        log-warn "Toolbox setup script not found at $toolbox_script"
    fi
}

# @description Main entry point.
main() {
    ensure-root

    disable-services
    configure-sysctl
    configure-cpu-governor
    configure-io-scheduler
    configure-tlp
    disable-gnome-software-autostart
    setup-dev-toolbox

    log-success "System optimized"
}

main "$@"
