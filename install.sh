#!/bin/bash

# FujiRuro-OS Installer - Master Setup Script
# A robust, interactive installer for Fujitsu ARROWS Tab optimizations.

set -e # Exit on error

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
BASE_DIR=$(dirname "$(readlink -f "$0")")
LOG_FILE="$BASE_DIR/install.log"

# Function to log messages
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${ORANGE}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)."
   exit 1
fi

log "Starting FujiRuro-OS Installation..."

# 1. Hardware Core Module
install_hardware() {
    log "Applying Hardware Fixes (Kernel & Boot)..."
    
    # GRUB Configuration
    GRUB_FILE="/etc/default/grub"
    if [ -f "$GRUB_FILE" ]; then
        log "Backing up GRUB config..."
        cp "$GRUB_FILE" "${GRUB_FILE}.bak"
        
        # Check if parameters already exist
        if grep -q "i2c_hid.polling_mode=1" "$GRUB_FILE"; then
            warn "Kernel parameters already seem to be present in $GRUB_FILE."
        else
            log "Injecting kernel parameters for rotation and touchscreen stability..."
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="i2c_hid.polling_mode=1 video=DSI-1:1200x1920,rotate=90 fbcon=rotate:1 /' "$GRUB_FILE"
            update-grub
            success "GRUB updated. A reboot will be required for changes to take effect."
        fi
    else
        error "Could not find $GRUB_FILE. Skipping GRUB optimizations."
    fi
}

# 2. Input & Buttons Module
install_input() {
    log "Configuring Input Devices (Buttons & Keyd)..."
    
    # Keyd setup
    if command -v keyd >/dev/null 2>&1; then
        log "Installing FujiRuro keyd configuration..."
        mkdir -p /etc/keyd
        cp "$BASE_DIR/input/keyd/fujiru.conf" /etc/keyd/default.conf
        keyd reload
        success "Keyd configuration applied."
    else
        warn "keyd is not installed. Skipping keyboard remapping."
    fi

    # Fujitsu Button Service
    log "Setting up Fujitsu Hardware Button service..."
    INSTALL_DIR="/usr/local/bin"
    cp "$BASE_DIR/input/fujitsu_buttons/handler.py" "$INSTALL_DIR/fujitsu_button_handler.py"
    chmod +x "$INSTALL_DIR/fujitsu_button_handler.py"
    
    cp "$BASE_DIR/input/fujitsu_buttons/fujitsu-button.service" /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable fujitsu-button.service
    
    # Sudoers entry for ftrace
    SUDOERS_FILE="/etc/sudoers.d/fujitsu_buttons"
    echo "%sudo ALL=(ALL) NOPASSWD: /usr/bin/cat /sys/kernel/debug/tracing/trace_pipe" > "$SUDOERS_FILE"
    echo "%sudo ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/kernel/debug/tracing/set_ftrace_filter" >> "$SUDOERS_FILE"
    echo "%sudo ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/kernel/debug/tracing/events/fujitsu_laptop/enable" >> "$SUDOERS_FILE"
    echo "%sudo ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/kernel/debug/tracing/current_tracer" >> "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    
    success "Hardware button service installed and enabled."
}

# 3. Sway Desktop Module
install_desktop() {
    log "Setting up FujiRuro Sway Desktop Environment..."
    
    USER_HOME=$(eval echo "~$SUDO_USER")
    CONFIG_DIR="$USER_HOME/.config"
    mkdir -p "$CONFIG_DIR/sway" "$CONFIG_DIR/waybar" "$USER_HOME/scripts"
    
    log "Deploying configuration files for user: $SUDO_USER"
    
    # Sanitize and copy Sway config
    cp "$BASE_DIR/desktop/sway/config" "$CONFIG_DIR/sway/config"
    sed -i "s|/home/oblivion|$USER_HOME|g" "$CONFIG_DIR/sway/config"
    
    # Copy scripts
    cp "$BASE_DIR/desktop/scripts/"* "$USER_HOME/scripts/"
    chmod +x "$USER_HOME/scripts/"*.sh
    sed -i "s|{{USER_HOME}}|$USER_HOME|g" "$USER_HOME/scripts/"*
    
    # Dynamic Rotation Service
    log "Setting up Dynamic Rotation service..."
    mkdir -p "$USER_HOME/.config/systemd/user"
    cp "$BASE_DIR/desktop/systemd/dynamic-rotation.service" "$USER_HOME/.config/systemd/user/"
    sed -i "s|{{USER_HOME}}|$USER_HOME|g" "$USER_HOME/.config/systemd/user/dynamic-rotation.service"
    
    # Optional Waybar Theme
    if [ "$INCLUDE_THEME" = "y" ]; then
        cp "$BASE_DIR/desktop/waybar/"* "$CONFIG_DIR/waybar/"
        sed -i "s|{{USER_HOME}}|$USER_HOME|g" "$CONFIG_DIR/waybar/"*
        # Set initial symlink
        ln -sf "$CONFIG_DIR/waybar/config.landscape" "$CONFIG_DIR/waybar/config"
    fi
    
    chown -R "$SUDO_USER:$SUDO_USER" "$CONFIG_DIR/sway" "$CONFIG_DIR/waybar" "$USER_HOME/scripts" "$USER_HOME/.config/systemd/user"
    
    # Enable rotation service for the user
    sudo -u "$SUDO_USER" XDG_RUNTIME_DIR="/run/user/$SUDO_UID" systemctl --user daemon-reload
    sudo -u "$SUDO_USER" XDG_RUNTIME_DIR="/run/user/$SUDO_UID" systemctl --user enable dynamic-rotation.service
    
    success "Desktop environment configured."
}

# Interactive Menu
echo -e "${BLUE}---------------------------------------------${NC}"
echo -e "${BLUE}       FujiRuro-OS Installer                ${NC}"
echo -e "${BLUE}---------------------------------------------${NC}"

read -p "Install Hardware Core (GRUB/Rotation)? [y/N]: " INSTALL_HW
read -p "Install Input Fixes (Buttons/Keyd)? [y/N]: " INSTALL_IN
read -p "Install Nomadic Sway Desktop? [y/N]: " INSTALL_DT

if [ "$INSTALL_DT" = "y" ]; then
    read -p "  Include visual theme (Waybar/Colors)? [y/N]: " INCLUDE_THEME
fi

[[ "$INSTALL_HW" =~ ^[Yy]$ ]] && install_hardware
[[ "$INSTALL_IN" =~ ^[Yy]$ ]] && install_input
[[ "$INSTALL_DT" =~ ^[Yy]$ ]] && install_desktop

log "Installation complete. Please check the log at $LOG_FILE"
warn "Note: You MUST reboot for kernel and hardware changes to take effect."
