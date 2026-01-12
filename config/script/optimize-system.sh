#!/usr/bin/env zsh
# Optimize System

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

# Disables and masks unnecessary services.
#
# Iterates through SERVICES_TO_DISABLE and SERVICES_TO_MASK arrays.
# @return void
disable-services() {
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

# Applies kernel optimizations via sysctl.
#
# Configures swappiness, cache pressure, and network settings.
# @return void
configure-sysctl() {
    log-info "Applying kernel optimizations..."
    
    local sysctl_config_file="/etc/sysctl.d/99-performance.conf"
    
    cat > "$sysctl_config_file" <<'EOF'
# Swappiness (100 for ZRAM to avoid file eviction)
vm.swappiness=100

# VFS cache pressure
vm.vfs_cache_pressure=50

# Dirty ratio (delay writes for better throughput)
vm.dirty_ratio=15
vm.dirty_background_ratio=5

# Network optimizations
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_congestion_control=bbr
net.core.default_qdisc=cake

# Maximize open file descriptors
fs.file-max=2097152

# Disable IPv6 if not needed (optional)
# net.ipv6.conf.all.disable_ipv6=1
EOF

    sysctl --system &>/dev/null
    log-success "Kernel parameters applied"
}

# Configures CPU Governor to performance.
#
# Tries to set governor for all cores.
# @return void
configure-cpu-governor() {
    log-info "Optimizing CPU governor..."
    
    # Try to set via cpupower if available, otherwise sysfs
    if command-exists cpupower; then
        cpupower frequency-set -g performance &>/dev/null || log-warn "cpupower failed"
    else
        # Fallback to direct sysfs manipulation (works on most modern kernels)
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            if [[ -f "$cpu" ]]; then
                echo "performance" > "$cpu" 2>/dev/null || true
            fi
        done
    fi
    log-success "CPU governor set to performance"
}

# Configures I/O Scheduler.
#
# Prefers BFQ for better desktop responsiveness.
# @return void
configure-io-scheduler() {
    log-info "Optimizing I/O scheduler..."
    
    # Apply to all non-loop block devices
    for dev in /sys/block/sd*(N) /sys/block/nvme*n*(N); do
        if [[ -f "$dev/queue/scheduler" ]]; then
            # Try bfq first, then mq-deadline, then none
            if grep -q "bfq" "$dev/queue/scheduler"; then
                echo "bfq" > "$dev/queue/scheduler" 2>/dev/null || true
            elif grep -q "mq-deadline" "$dev/queue/scheduler"; then
                echo "mq-deadline" > "$dev/queue/scheduler" 2>/dev/null || true
            fi
        fi
    done
    
    # Persistent udev rule for I/O scheduler
    cat > "/etc/udev/rules.d/60-io-scheduler.rules" <<'EOF'
# NVMe SSDs
ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="bfq"
# SATA/HDD
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/scheduler}="bfq"
EOF
    
    udevadm control --reload 2>/dev/null || true
    log-success "I/O scheduler optimized"
}

# Configures TLP for power management.
#
# Enables TLP service and masks conflicting systemd-rfkill services.
# @return void
configure-tlp() {
    if ! command -v tlp &>/dev/null; then
        log-info "TLP not installed, skipping"
        return
    fi
    
    log-info "Enabling TLP..."
    systemctl enable --now tlp.service 2>/dev/null || log-warn "Failed to enable TLP service"
    systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>/dev/null || log-warn "Failed to mask systemd-rfkill"
    
    # Ensure TLP performance mode on AC
    sed -i 's/^CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC="performance"/' /etc/tlp.conf 2>/dev/null || true
    sed -i 's/^CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC="performance"/' /etc/tlp.conf 2>/dev/null || true
    
    log-success "TLP configured"
}

# Disables GNOME Software autostart.
#
# Adds Hidden=true to the autostart desktop entry.
# @return void
disable-gnome-software-autostart() {
    local autostart_directory="/etc/xdg/autostart"
    local gnome_software_desktop_entry="$autostart_directory/org.gnome.Software.desktop"
    
    if [[ -f "$gnome_software_desktop_entry" ]]; then
        log-info "Disabling GNOME Software autostart..."
        echo "Hidden=true" >> "$gnome_software_desktop_entry" 2>/dev/null || log-warn "Failed to disable GNOME Software autostart"
    fi
}

main() {
    ensure-root
    
    disable-services
    configure-sysctl
    configure-cpu-governor
    configure-io-scheduler
    configure-tlp
    disable-gnome-software-autostart
    
    log-success "System optimized"
}

main "$@"
