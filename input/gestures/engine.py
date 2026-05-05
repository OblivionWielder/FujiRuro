import evdev
from evdev import ecodes
import subprocess
import os
import sys

# Sanitized Touch Gestures Engine for FujiRuro-OS
# Interprets raw evdev data into Sway commands, accounting for 90-degree rotation.

THRESHOLD = 350
DEV_NAME = "FTSC1000:00 2808:2922"

def get_device():
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    for device in devices:
        if "FTSC1000" in device.name and "UNKNOWN" not in device.name:
            return device
    return None

def run_sway_cmd(cmd):
    env = os.environ.copy()
    uid = str(os.getuid())
    if 'SWAYSOCK' not in env:
        try:
            # Attempt to find the socket automatically
            socks = subprocess.check_output(f"ls /run/user/{uid}/sway-ipc.*.sock", shell=True, text=True).split()
            if socks: env['SWAYSOCK'] = socks[0]
        except: pass
    subprocess.run(["swaymsg", cmd], env=env)

def main():
    device = get_device()
    if not device: 
        sys.exit(1)

    start_x, start_y = None, None
    curr_x, curr_y = 0, 0
    triggered = False
    
    for event in device.read_loop():
        if event.type == ecodes.EV_ABS:
            if event.code == ecodes.ABS_MT_POSITION_X or event.code == ecodes.ABS_X:
                curr_x = event.value
            elif event.code == ecodes.ABS_MT_POSITION_Y or event.code == ecodes.ABS_Y:
                curr_y = event.value
                
        elif event.type == ecodes.EV_KEY and event.code == ecodes.BTN_TOUCH:
            if event.value == 1: # Touch Down
                start_x, start_y = curr_x, curr_y
                triggered = False
            else: # Touch Up
                start_x, start_y = None, None

        if start_x is not None and not triggered:
            dx = curr_x - start_x
            dy = curr_y - start_y
            
            # 90 DEG ROTATION LOGIC for WUXGA (1200x1920)
            # dy > 0: Swipe Down (Portrait) -> Swipe Left (Landscape)
            # dy < 0: Swipe Up (Portrait) -> Swipe Right (Landscape)
            
            if abs(dy) > THRESHOLD:
                if dy > 0:
                    run_sway_cmd("workspace next")
                    triggered = True
                else:
                    run_sway_cmd("workspace prev")
                    triggered = True
            elif abs(dx) > THRESHOLD:
                if dx > 0:
                    run_sway_cmd("floating toggle")
                    triggered = True

if __name__ == "__main__":
    main()
