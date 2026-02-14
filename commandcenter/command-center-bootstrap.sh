#!/usr/bin/env bash
# Command Center Bootstrap - AMD/ROCm Edition
# Optimized for AMD Ryzen 7 7700 + AMD GPU with ROCm
set -euo pipefail

#==============================
# System Configuration
#==============================
NODE_EXPORTER_VERSION="1.8.1"
AMD_EXPORTER_VERSION="1.1.0"
NODE_EXPORTER_PORT=9100
AMD_GPU_EXPORTER_PORT=9400
PROM_CONFIG_PATH="/etc/prometheus/prometheus.yml"
TARGETS_FILE="/etc/prometheus/targets/command-center-exporters.yml"
COMMAND_CENTER_LABEL="command-center"
BRAIN_HOST="192.168.1.9"
BRAWN_HOST="192.168.1.222"
AI_USER="jb"

#==============================
# Helpers
#==============================
log() { echo "[command-center-bootstrap] $*"; }
err() { echo "[command-center-bootstrap][error] $*" >&2; }
warn() { echo "[command-center-bootstrap][warning] $*" >&2; }

require_root() {
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        err "This script must be run as root."
        exit 1
    fi
}

require_cmd() {
    local cmd=$1
    if ! command -v "$cmd" >/dev/null 2>&1; then
        err "Missing dependency: $cmd"
        exit 1
    fi
}

#==============================
# System Setup
#==============================
setup_user_permissions() {
    log "Setting up permissions for user: ${AI_USER}"

    # Add user to render group for GPU access
    if ! groups "$AI_USER" | grep -q '\brender\b'; then
        log "Adding ${AI_USER} to 'render' group..."
        usermod -aG render "$AI_USER"
    else
        log "User ${AI_USER} already in 'render' group"
    fi

    # Add user to video group
    if ! groups "$AI_USER" | grep -q '\bvideo\b'; then
        log "Adding ${AI_USER} to 'video' group..."
        usermod -aG video "$AI_USER"
    else
        log "User ${AI_USER} already in 'video' group"
    fi

    log "✅ User permissions configured. User must log out and back in for changes to take effect."
}

setup_mount_points() {
    log "Checking mount points..."

    # Create /mnt/jai_data if it doesn't exist
    if [[ ! -d "/mnt/jai_data" ]]; then
        log "Creating /mnt/jai_data directory..."
        mkdir -p /mnt/jai_data
        chown "${AI_USER}:${AI_USER}" /mnt/jai_data
        chmod 755 /mnt/jai_data
    fi

    # Check if we need to mount a specific drive
    # Assuming nvme1n1 (1.8TB) is for AI data
    if ! mountpoint -q /mnt/jai_data; then
        warn "AI data drive NOT mounted at /mnt/jai_data"
        warn "To mount nvme1n1 (1.8TB drive), run:"
        warn "  sudo mkfs.ext4 /dev/nvme1n1  # CAUTION: This will erase the drive!"
        warn "  sudo mount /dev/nvme1n1 /mnt/jai_data"
        warn "  echo '/dev/nvme1n1 /mnt/jai_data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab"
    else
        log "✅ AI data drive mounted at /mnt/jai_data"
    fi
}

verify_amd_gpu() {
    log "Verifying AMD GPU setup..."

    # Check for AMD GPU
    if ! lspci | grep -i "amd.*vga\|amd.*display\|amd.*3d" >/dev/null 2>&1; then
        warn "AMD GPU not detected via lspci"
        return 1
    fi

    # Check for amdgpu kernel module
    if ! lsmod | grep -q amdgpu; then
        warn "amdgpu kernel module not loaded"
        return 1
    fi

    # Check for ROCm
    if [[ -e /dev/kfd ]]; then
        log "✅ ROCm interface detected (/dev/kfd)"
    else
        warn "ROCm interface NOT detected (/dev/kfd missing)"
    fi

    # Check for render node
    if [[ -e /dev/dri/renderD128 ]]; then
        log "✅ Render node detected (/dev/dri/renderD128)"
    else
        warn "Render node NOT detected"
    fi

    log "✅ AMD GPU verification complete"
    return 0
}

#==============================
# Exporter installers
#==============================
install_node_exporter() {
    if systemctl is-active --quiet node_exporter; then
        log "node_exporter already running; skipping install."
        return
    fi

    require_cmd curl
    require_cmd tar

    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l) arch="armv7" ;;
        *) err "Unsupported architecture: $arch"; exit 1 ;;
    esac

    local tmpdir
    tmpdir=$(mktemp -d)
    pushd "$tmpdir" >/dev/null
    local pkg="node_exporter-${NODE_EXPORTER_VERSION}.linux-${arch}.tar.gz"
    curl -fsSLO "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${pkg}"
    tar -xzf "$pkg"
    install -m 0755 "node_exporter-${NODE_EXPORTER_VERSION}.linux-${arch}/node_exporter" /usr/local/bin/node_exporter
    popd >/dev/null
    rm -rf "$tmpdir"

    # system user
    if ! id -u node_exporter >/dev/null 2>&1; then
        useradd --no-create-home --system --shell /usr/sbin/nologin node_exporter
    fi

cat >/etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=":${NODE_EXPORTER_PORT}"
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now node_exporter
    log "✅ node_exporter installed and listening on :${NODE_EXPORTER_PORT}"
}

install_amd_gpu_exporter() {
    # Check if AMD GPU exists
    if ! verify_amd_gpu; then
        log "No AMD GPU detected or ROCm not configured; skipping AMD GPU exporter."
        return
    fi

    if systemctl is-active --quiet amd_gpu_exporter; then
        log "amd_gpu_exporter already running; skipping install."
        return
    fi

    # For AMD GPUs, we'll use a custom exporter based on rocm-smi or amd-smi
    # First, check if rocm-smi is available
    if command -v rocm-smi >/dev/null 2>&1; then
        install_rocm_exporter
    elif command -v amd-smi >/dev/null 2>&1; then
        install_amd_smi_exporter
    else
        warn "Neither rocm-smi nor amd-smi found. Installing basic AMD GPU exporter..."
        install_basic_amd_exporter
    fi
}

install_rocm_exporter() {
    log "Installing ROCm GPU exporter..."

    # Create a simple exporter script that uses rocm-smi
    cat >/usr/local/bin/amd_gpu_exporter <<'EOF'
#!/usr/bin/env python3
"""
Simple AMD GPU Prometheus Exporter using rocm-smi
"""
import subprocess
import time
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 9400

class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/metrics':
            metrics = self.get_metrics()
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(metrics.encode())
        else:
            self.send_response(404)
            self.end_headers()

    def get_metrics(self):
        try:
            result = subprocess.run(['rocm-smi', '--showtemp', '--showuse', '--showmeminfo', 'vram'],
                                    capture_output=True, text=True, timeout=5)
            output = result.stdout

            # Parse rocm-smi output and create Prometheus metrics
            metrics = []
            metrics.append('# HELP amd_gpu_temperature GPU Temperature in Celsius')
            metrics.append('# TYPE amd_gpu_temperature gauge')

            # Extract temperature (this is a simplified parser - adjust based on actual output)
            for line in output.split('\n'):
                if 'Temperature' in line or 'c' in line.lower():
                    try:
                        temp = [int(s) for s in line.split() if s.isdigit()][0]
                        metrics.append(f'amd_gpu_temperature{{gpu="0"}} {temp}')
                    except:
                        pass

            metrics.append('')
            return '\n'.join(metrics)
        except Exception as e:
            return f'# Error getting metrics: {str(e)}\n'

    def log_message(self, format, *args):
        pass  # Suppress HTTP logs

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', PORT), MetricsHandler)
    print(f'AMD GPU Exporter listening on port {PORT}')
    server.serve_forever()
EOF

    chmod +x /usr/local/bin/amd_gpu_exporter

    if ! id -u amd_gpu_exporter >/dev/null 2>&1; then
        useradd --no-create-home --system --shell /usr/sbin/nologin amd_gpu_exporter
        usermod -aG video amd_gpu_exporter
        usermod -aG render amd_gpu_exporter
    fi

    cat >/etc/systemd/system/amd_gpu_exporter.service <<EOF
[Unit]
Description=Prometheus AMD GPU Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=amd_gpu_exporter
Group=amd_gpu_exporter
Type=simple
ExecStart=/usr/local/bin/amd_gpu_exporter
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now amd_gpu_exporter
    log "✅ AMD GPU exporter (ROCm) installed and listening on :${AMD_GPU_EXPORTER_PORT}"
}

install_amd_smi_exporter() {
    log "Installing AMD SMI GPU exporter..."
    # Similar to rocm exporter but uses amd-smi
    warn "amd-smi exporter not yet implemented, falling back to basic exporter"
    install_basic_amd_exporter
}

install_basic_amd_exporter() {
    log "Installing basic AMD GPU exporter (sysfs-based)..."

    cat >/usr/local/bin/amd_gpu_exporter <<'EOF'
#!/usr/bin/env python3
"""
Basic AMD GPU Prometheus Exporter using sysfs
"""
import os
import time
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 9400

class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/metrics':
            metrics = self.get_metrics()
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(metrics.encode())
        else:
            self.send_response(404)
            self.end_headers()

    def get_metrics(self):
        metrics = []

        # Check for AMD GPU hwmon
        hwmon_path = '/sys/class/drm/card0/device/hwmon'
        if os.path.exists(hwmon_path):
            hwmon_dirs = [d for d in os.listdir(hwmon_path) if d.startswith('hwmon')]
            if hwmon_dirs:
                hwmon = os.path.join(hwmon_path, hwmon_dirs[0])

                # Temperature
                temp_file = os.path.join(hwmon, 'temp1_input')
                if os.path.exists(temp_file):
                    with open(temp_file) as f:
                        temp = int(f.read().strip()) / 1000.0
                    metrics.append('# HELP amd_gpu_temperature GPU Temperature in Celsius')
                    metrics.append('# TYPE amd_gpu_temperature gauge')
                    metrics.append(f'amd_gpu_temperature{{gpu="0"}} {temp}')
                    metrics.append('')

                # Power usage
                power_file = os.path.join(hwmon, 'power1_average')
                if os.path.exists(power_file):
                    with open(power_file) as f:
                        power = int(f.read().strip()) / 1000000.0  # Convert to watts
                    metrics.append('# HELP amd_gpu_power_watts GPU Power Usage in Watts')
                    metrics.append('# TYPE amd_gpu_power_watts gauge')
                    metrics.append(f'amd_gpu_power_watts{{gpu="0"}} {power}')
                    metrics.append('')

        # GPU busy percentage
        busy_file = '/sys/class/drm/card0/device/gpu_busy_percent'
        if os.path.exists(busy_file):
            with open(busy_file) as f:
                busy = int(f.read().strip())
            metrics.append('# HELP amd_gpu_utilization GPU Utilization Percentage')
            metrics.append('# TYPE amd_gpu_utilization gauge')
            metrics.append(f'amd_gpu_utilization{{gpu="0"}} {busy}')
            metrics.append('')

        return '\n'.join(metrics) if metrics else '# No AMD GPU metrics available\n'

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', PORT), MetricsHandler)
    print(f'AMD GPU Exporter (sysfs) listening on port {PORT}')
    server.serve_forever()
EOF

    chmod +x /usr/local/bin/amd_gpu_exporter

    if ! id -u amd_gpu_exporter >/dev/null 2>&1; then
        useradd --no-create-home --system --shell /usr/sbin/nologin amd_gpu_exporter
        usermod -aG video amd_gpu_exporter
        usermod -aG render amd_gpu_exporter
    fi

    cat >/etc/systemd/system/amd_gpu_exporter.service <<EOF
[Unit]
Description=Prometheus AMD GPU Exporter (sysfs)
Wants=network-online.target
After=network-online.target

[Service]
User=amd_gpu_exporter
Group=amd_gpu_exporter
Type=simple
ExecStart=/usr/local/bin/amd_gpu_exporter
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now amd_gpu_exporter
    log "✅ AMD GPU exporter (sysfs) installed and listening on :${AMD_GPU_EXPORTER_PORT}"
}

#==============================
# Prometheus configuration
#==============================
write_prometheus_targets() {
    mkdir -p "$(dirname "$TARGETS_FILE")"
    cat >"$TARGETS_FILE" <<EOF
- job_name: 'node_exporter'
  metrics_path: /metrics
  static_configs:
    - targets:
      - "localhost:${NODE_EXPORTER_PORT}"
      - "${BRAIN_HOST}:${NODE_EXPORTER_PORT}"
      - "${BRAWN_HOST}:${NODE_EXPORTER_PORT}"
      labels:
        role: node-exporter

- job_name: 'amd_gpu_exporter'
  metrics_path: /metrics
  static_configs:
    - targets:
      - "localhost:${AMD_GPU_EXPORTER_PORT}"
      - "${BRAIN_HOST}:${AMD_GPU_EXPORTER_PORT}"
      - "${BRAWN_HOST}:${AMD_GPU_EXPORTER_PORT}"
      labels:
        role: gpu-exporter
EOF
    log "✅ Prometheus target file updated at ${TARGETS_FILE}."
}

append_prometheus_config_hint() {
    if [[ ! -f "$PROM_CONFIG_PATH" ]]; then
        log "Prometheus config not found at ${PROM_CONFIG_PATH}; creating minimal config."
        mkdir -p "$(dirname "$PROM_CONFIG_PATH")"
        cat >"$PROM_CONFIG_PATH" <<'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF
    fi

    if ! grep -q "$TARGETS_FILE" "$PROM_CONFIG_PATH"; then
        cat >>"$PROM_CONFIG_PATH" <<EOF

# Command Center exporters (AMD/ROCm Edition)
- job_name: 'file_sd_command_center'
  file_sd_configs:
    - files:
        - '${TARGETS_FILE}'
EOF
        log "✅ Appended file_sd reference to ${PROM_CONFIG_PATH}."
    else
        log "Prometheus config already references ${TARGETS_FILE}."
    fi
}

#==============================
# Remote propagation
#==============================
ssh_push_exporters() {
    local host=$1
    log "Attempting SSH push to ${host}..."
    ssh "${host}" "bash -s" <<'EOSSH'
set -euo pipefail
NODE_EXPORTER_VERSION="1.8.1"
NODE_EXPORTER_PORT=9100
AMD_GPU_EXPORTER_PORT=9400

install_exporter() {
    local name=$1 version=$2 binary=$3 service=$4 port=$5 url=$6
    if systemctl is-active --quiet "$service"; then
        echo "$service already running"
        return
    fi
    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l) arch="armv7" ;;
        *) echo "Unsupported arch: $arch"; exit 1 ;;
    esac
    tmpdir=$(mktemp -d)
    cd "$tmpdir"
    pkg="${name}-${version}.linux-${arch}.tar.gz"
    curl -fsSLO "$url/${version}/${pkg}"
    tar -xzf "$pkg"
    install -m 0755 "${name}-${version}.linux-${arch}/${binary}" "/usr/local/bin/${binary}"
    rm -rf "$tmpdir"
    if ! id -u "$service" >/dev/null 2>&1; then
        useradd --no-create-home --system --shell /usr/sbin/nologin "$service"
    fi
    cat >/etc/systemd/system/${service}.service <<EOF
[Unit]
Description=Prometheus ${name}
Wants=network-online.target
After=network-online.target
[Service]
User=${service}
Group=${service}
ExecStart=/usr/local/bin/${binary} --web.listen-address=":${port}"
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now ${service}
}

install_exporter "node_exporter" "$NODE_EXPORTER_VERSION" "node_exporter" "node_exporter" "$NODE_EXPORTER_PORT" "https://github.com/prometheus/node_exporter/releases/download/v"

# AMD GPU exporter (basic sysfs version for remote hosts)
if lsmod | grep -q amdgpu; then
    echo "AMD GPU detected, installing basic exporter..."
    # Copy the basic AMD exporter script (simplified version for remote)
    cat >/usr/local/bin/amd_gpu_exporter <<'EXPORTEREOF'
#!/usr/bin/env python3
import os
from http.server import HTTPServer, BaseHTTPRequestHandler
PORT = 9400
class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/metrics':
            metrics = []
            hwmon_path = '/sys/class/drm/card0/device/hwmon'
            if os.path.exists(hwmon_path):
                hwmon_dirs = [d for d in os.listdir(hwmon_path) if d.startswith('hwmon')]
                if hwmon_dirs:
                    hwmon = os.path.join(hwmon_path, hwmon_dirs[0])
                    temp_file = os.path.join(hwmon, 'temp1_input')
                    if os.path.exists(temp_file):
                        with open(temp_file) as f:
                            temp = int(f.read().strip()) / 1000.0
                        metrics.append(f'amd_gpu_temperature{{gpu="0"}} {temp}')
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write('\n'.join(metrics).encode())
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, *args): pass
if __name__ == '__main__':
    HTTPServer(('0.0.0.0', PORT), MetricsHandler).serve_forever()
EXPORTEREOF
    chmod +x /usr/local/bin/amd_gpu_exporter
    if ! id -u amd_gpu_exporter >/dev/null 2>&1; then
        useradd --no-create-home --system --shell /usr/sbin/nologin amd_gpu_exporter
        usermod -aG video amd_gpu_exporter
        usermod -aG render amd_gpu_exporter
    fi
    cat >/etc/systemd/system/amd_gpu_exporter.service <<'SERVICEEOF'
[Unit]
Description=AMD GPU Exporter
After=network.target
[Service]
User=amd_gpu_exporter
Group=amd_gpu_exporter
ExecStart=/usr/local/bin/amd_gpu_exporter
Restart=on-failure
[Install]
WantedBy=multi-user.target
SERVICEEOF
    systemctl daemon-reload
    systemctl enable --now amd_gpu_exporter
fi
EOSSH
}

#==============================
# CLI handling
#==============================
REMOTE_METHOD=""
REMOTE_TARGETS=()

usage() {
    cat <<EOF
Usage: sudo ./command-center-bootstrap.sh [options]
  --brain <host>     Brain hostname or IP (default ${BRAIN_HOST})
  --brawn <host>     Brawn hostname or IP (default ${BRAWN_HOST})
  --push-remote      Push exporters to Brain and Brawn
  --method <ssh>     Method for remote push (default ssh)
  --user <username>  AI user for permissions (default ${AI_USER})
  --setup-system     Setup mount points and user permissions
  --verify-gpu       Verify AMD GPU and ROCm configuration
EOF
}

SETUP_SYSTEM=false
VERIFY_GPU_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --brain) BRAIN_HOST=$2; shift 2 ;;
        --brawn) BRAWN_HOST=$2; shift 2 ;;
        --push-remote) REMOTE_TARGETS=("$BRAIN_HOST" "$BRAWN_HOST"); shift ;;
        --method) REMOTE_METHOD=$2; shift 2 ;;
        --user) AI_USER=$2; shift 2 ;;
        --setup-system) SETUP_SYSTEM=true; shift ;;
        --verify-gpu) VERIFY_GPU_ONLY=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) err "Unknown option: $1"; usage; exit 1 ;;
    esac
done

main() {
    require_root

    if [[ "$VERIFY_GPU_ONLY" == true ]]; then
        verify_amd_gpu
        exit 0
    fi

    if [[ "$SETUP_SYSTEM" == true ]]; then
        setup_user_permissions
        setup_mount_points
    fi

    verify_amd_gpu || warn "AMD GPU verification failed, continuing anyway..."

    install_node_exporter
    install_amd_gpu_exporter
    write_prometheus_targets
    append_prometheus_config_hint

    if [[ ${#REMOTE_TARGETS[@]} -gt 0 ]]; then
        for host in "${REMOTE_TARGETS[@]}"; do
            ssh_push_exporters "$host" || warn "Failed to push to $host"
        done
    fi

    log ""
    log "========================================="
    log "✅ Command Center Bootstrap Complete"
    log "========================================="
    log ""
    log "Next steps:"
    log "  1. User '${AI_USER}' should log out and back in for group changes"
    log "  2. Verify exporters: curl http://localhost:${NODE_EXPORTER_PORT}/metrics"
    log "  3. Check AMD GPU: curl http://localhost:${AMD_GPU_EXPORTER_PORT}/metrics"
    log "  4. Mount AI data drive if needed (see warnings above)"
    log "  5. Deploy docker-compose.yml with: docker compose up -d"
    log ""
}

main "$@"
