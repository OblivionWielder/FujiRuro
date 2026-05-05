#!/bin/bash
# Standalone Hardware Module for FujiRuro-OS
# Handles GRUB and kernel parameter injection.

GRUB_FILE="/etc/default/grub"
PARAMS="i2c_hid.polling_mode=1 video=DSI-1:1200x1920,rotate=90 fbcon=rotate:1"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

echo "[Hardware] Injecting: $PARAMS"
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$PARAMS /" "$GRUB_FILE"

echo "[Hardware] Updating GRUB..."
update-grub

echo "[Hardware] Rebuilding initramfs for early KMS (i915)..."
echo "i915" >> /etc/initramfs-tools/modules
update-initramfs -u

echo "[Hardware] Complete. Please REBOOT."
