#!/bin/bash
# ZRAM Setup for FujiRuro-OS
# Optimized for 4GB RAM devices using zstd compression.

log() { echo "[ZRAM] $1"; }

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

log "Installing zram-tools..."
apt-get update && apt-get install -y zram-tools

log "Configuring ZRAM (1.8GB, zstd)..."
cat << 'EOF' > /etc/default/zramswap
# ZRAM configuration for FujiRuro-OS
ALGO=zstd
SIZE=1800
PRIORITY=100
EOF

log "Restarting ZRAM service..."
systemctl restart zramswap
zramctl

success "ZRAM is active."
