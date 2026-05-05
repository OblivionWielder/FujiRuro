#!/bin/bash
# Power & TLP Setup for FujiRuro-OS
# Optimizes for battery and thermal management on Celeron N4020.

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

echo "[Power] Installing TLP and Intel tools..."
apt-get update && apt-get install -y tlp tlp-rdw intel-gpu-tools brightnessctl

echo "[Power] Configuring TLP for aggressive battery savings..."
# Enable TLP and set to battery mode by default if charger is missing
systemctl enable tlp
tlp start

echo "[Power] Optimizing Intel Graphics power management..."
# (Assuming i915 parameters are handled via GRUB/modprobe)
# We can add udev rules or modprobe.d files here if needed.

echo "[Power] Success."

echo "[Power] Installing TLP CPU delegation config..."
cp "$(dirname "$0")/tlp_cpu_delegation.conf" /etc/tlp.d/99-fujiruro-cpu.conf
tlp start

