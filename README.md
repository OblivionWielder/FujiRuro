# FujiRuro: The Nomadic Fujitsu ARROWS Tab Experience

FujiRuro is a collection of optimizations, scripts, and configurations designed to transform the Fujitsu ARROWS Tab Q5010/EEG (and similar Gemini Lake-based tablets) into a high-performance, battery-efficient nomadic workstation.

The name is a portmanteau of **Fujitsu** and **Ruro** (流浪 - wandering/nomadic), reflecting the goal of creating a device that is as capable as it is portable, even on modest hardware.

## The Hardware Challenge

The Fujitsu ARROWS Tab is a popular, affordable tablet on the second-hand market, but it presents several significant hurdles for Linux users:

1.  **Portrait-Native Screen**: The display panel is natively 1200x1920 (Portrait). Without specific kernel flags and window manager configurations, the boot process and desktop environment will be sideways or inverted.
2.  **Touchscreen Calibration**: Because the screen is rotated 90 degrees in software, the touchscreen input axes must be manually re-mapped to match the visual display.
3.  **FTSC1000 Driver Issues**: The I2C HID touchscreen driver often suffers from "incomplete report" errors, causing jerky or non-functional touch input.
4.  **Hardware Buttons**: The device features dedicated physical buttons (Fujitsu FUJ02E3) that are not recognized as standard keyboard keys by default.
5.  **Resource Constraints**: With an Intel Celeron N4020 and 4GB of RAM, modern heavy desktop environments like GNOME or KDE can feel sluggish.

## Our Solutions

This repository provides a "Bootstrap" installation that addresses these issues through:

### 1. Kernel & Boot Optimizations
We inject specific flags into GRUB to ensure the screen is rotated from the very first second of boot (`video=DSI-1:1200x1920,rotate=90`) and that the touchscreen driver is forced into a stable polling mode (`i2c_hid.polling_mode=1`).

### 2. The Nomadic Desktop (Sway)
We use **Sway** (a Wayland tiling window manager) because it handles display rotation and touchscreen mapping more efficiently and reliably than X11-based systems on this hardware. Our configuration includes a custom `calibration_matrix` for the FTSC1000.

### 3. Native Hardware Button Support
We include a Python-based background service that monitors the kernel's `ftrace` pipe to detect physical button presses, allowing you to map them to actions like screenshots, launching a terminal, or system updates.

### 4. Dynamic Screen Rotation
Utilizing the tablet's built-in accelerometer via `iio-sensor-proxy`, we provide a dynamic listener that automatically rotates the Sway workspace and adapts the Waybar UI. In portrait mode, Waybar automatically switches to a high-density, multi-row layout to prevent widget overflow.

### 5. Optimized Input (The Spanish-Nomadic Layout)
Using **keyd**, we transform the Japanese JP106 keyboard into a powerhouse for Spanish-speaking developers, adding a custom layer for accents (á, é, í, ó, ú, ñ) and remapping underutilized keys to common application shortcuts.

### 5. Extreme Efficiency
Everything in FujiRuro is chosen for speed and battery life. We prioritize TUI (Terminal User Interface) applications like `yazi`, `newsboat`, and `helix` to keep memory usage low and the system responsive.

## Getting Started

1.  Install a base **Debian Trixie (Testing)** system (Standard System Utilities and SSH Server only, no Desktop Environment).
2.  Clone this repository:
    `git clone https://github.com/OblivionWielder/FujiRuro.git`
3.  Run the installer:
    `cd FujiRuro && sudo ./install.sh`

The installer is interactive and will allow you to choose which components to apply.

---
*This project is born out of the necessity to make limited hardware feel unlimited. Wander far, work efficiently.*
