#!/usr/bin/env python3
import time
import os
import subprocess
import signal
import sys

# --- Configuration ---
SENSOR_PATH = "/sys/bus/iio/devices/iio:device0/in_illuminance_input"
BACKLIGHT_PATH = "/sys/class/backlight/intel_backlight"
MIN_BRIGHTNESS_PCT = 5
MAX_BRIGHTNESS_PCT = 100
POLL_INTERVAL = 2 # Seconds
SMOOTHING_SAMPLES = 3 # Number of samples to average
HYSTERESIS_PCT = 3 # Only change if delta is > 3%

# PID File for toggle logic
PID_FILE = "/tmp/auto_brightness.pid"

def get_max_brightness():
    with open(os.path.join(BACKLIGHT_PATH, "max_brightness"), "r") as f:
        return int(f.read().strip())

def get_current_brightness():
    with open(os.path.join(BACKLIGHT_PATH, "brightness"), "r") as f:
        return int(f.read().strip())

def set_brightness(percent):
    max_b = get_max_brightness()
    target = int((percent / 100.0) * max_b)
    with open(os.path.join(BACKLIGHT_PATH, "brightness"), "w") as f:
        f.write(str(target))

def get_lux():
    try:
        with open(SENSOR_PATH, "r") as f:
            return int(f.read().strip())
    except Exception:
        return None

def lux_to_percent(lux):
    """
    Logarithmic mapping for human eye perception.
    Typical indoor: 100-500 lux
    Direct sunlight: 10,000+ lux
    """
    if lux <= 0: return MIN_BRIGHTNESS_PCT
    if lux < 10: return 10
    if lux < 100: return 30
    if lux < 500: return 50
    if lux < 1000: return 70
    return MAX_BRIGHTNESS_PCT

def main():
    # Write PID
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

    samples = []
    last_set_pct = -1

    try:
        while True:
            lux = get_lux()
            if lux is not None:
                samples.append(lux_to_percent(lux))
                if len(samples) > SMOOTHING_SAMPLES:
                    samples.pop(0)
                
                avg_pct = sum(samples) / len(samples)
                
                # Apply hysteresis
                if abs(avg_pct - last_set_pct) >= HYSTERESIS_PCT:
                    set_brightness(avg_pct)
                    last_set_pct = avg_pct
            
            time.sleep(POLL_INTERVAL)
    except KeyboardInterrupt:
        pass
    finally:
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "stop":
        if os.path.exists(PID_FILE):
            with open(PID_FILE, "r") as f:
                pid = int(f.read().strip())
                os.kill(pid, signal.SIGTERM)
            sys.exit(0)
    
    main()
