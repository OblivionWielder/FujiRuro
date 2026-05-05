import subprocess
import time
import os
import sys
import select
import fcntl
import glob

# Sanitized Button Handler for FujiRuro-OS
# Monitors /sys/kernel/debug/tracing/trace_pipe for fujitsu_laptop events.
# Specialized for Fujitsu ARROWS Tab Q5010/EEG (Celeron N4020).
# Includes Magnet/Lid event filtering, Resume immunity, and Pulse Accumulator logic.

LOGFILE = os.path.expanduser("~/fujitsu_button.log")

def log(msg):
    # Log Rotation: Prevent storage bloat
    try:
        if os.path.exists(LOGFILE) and os.path.getsize(LOGFILE) > 1024 * 1024:
            with open(LOGFILE, "r") as f:
                lines = f.readlines()
            with open(LOGFILE, "w") as f:
                f.writelines(lines[-100:])
            with open(LOGFILE, "a") as f:
                f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - --- LOG ROTATED ---\n")
    except Exception:
        pass

    with open(LOGFILE, "a") as f:
        f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} - {msg}\n")

def lock_file():
    lock_file_path = "/tmp/fujitsu_button_handler.lock"
    f = open(lock_file_path, 'w')
    try:
        fcntl.lockf(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return f
    except IOError:
        sys.exit(0)

lock = lock_file()

# Commands (Relative to user's scripts folder)
SCRIPTS_DIR = os.path.expanduser("~/scripts")
CMD_SNIP = os.path.join(SCRIPTS_DIR, "snip.sh")
CMD_GEMINI = "foot sudo gemini --latest"
CMD_UPDATE = os.path.join(SCRIPTS_DIR, "update_system.sh")

def find_swaysock():
    uid = os.getuid()
    path_pattern = f"/run/user/{uid}/sway-ipc.{uid}.*.sock"
    sockets = glob.glob(path_pattern)
    if sockets:
        return sorted(sockets, key=os.path.getmtime)[-1]
    return None

def run_cmd(cmd):
    log(f"Executing: {cmd}")
    swaysock = find_swaysock()
    if swaysock:
        os.environ["SWAYSOCK"] = swaysock

    try:
        subprocess.run(f"/usr/bin/swaymsg exec \"{cmd}\"", shell=True, capture_output=True, text=True, env=os.environ)
    except Exception as e:
        log(f"Failed to launch: {e}")

def setup_ftrace():
    log("Setting up ftrace...")
    cmds = [
        "echo acpi_fujitsu_laptop_notify | sudo /usr/bin/tee /sys/kernel/debug/tracing/set_ftrace_filter",
        "echo 1 | sudo /usr/bin/tee /sys/kernel/debug/tracing/events/fujitsu_laptop/enable",
        "echo function | sudo /usr/bin/tee /sys/kernel/debug/tracing/current_tracer"
    ]
    for cmd in cmds:
        subprocess.run(cmd, shell=True)

def is_lid_closed():
    try:
        with open("/proc/acpi/button/lid/LID/state", "r") as f:
            return "closed" in f.read().lower()
    except Exception:
        return False

def get_uptime():
    try:
        with open("/proc/uptime", "r") as f:
            return float(f.readline().split()[0])
    except Exception:
        return time.time()

def main():
    setup_ftrace()
    
    p = subprocess.Popen(['sudo', '/usr/bin/cat', '/sys/kernel/debug/tracing/trace_pipe'], 
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1)
    
    # Timing constants
    ACCUMULATION_WINDOW = 0.8 # Seconds to wait after the LAST pulse before triggering
    
    pulse_count = 0
    last_event_time = 0
    last_loop_time = time.time()
    last_uptime = get_uptime()
    resume_time = 0
    
    fd = p.stdout.fileno()
    fl = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
    
    while True:
        r, _, _ = select.select([p.stdout], [], [], 0.1)
        now = time.time()
        uptime = get_uptime()
        
        wall_delta = now - last_loop_time
        uptime_delta = uptime - last_uptime
        
        if uptime_delta < (wall_delta - 2.0) and wall_delta > 5.0:
            log(f"System resume detected. Resetting state.")
            resume_time = now
            pulse_count = 0
            
        last_uptime = uptime
        last_loop_time = now

        if r:
            line = p.stdout.readline()
            if line and "acpi_fujitsu_laptop_notify" in line:
                if is_lid_closed():
                    log("Pulse ignored: Lid magnet sensor active.")
                    pulse_count = 0
                    continue
                
                if (now - resume_time) < 2.5:
                    log("Pulse ignored: Post-resume magnet noise.")
                    pulse_count = 0
                    continue

                # Accumulate pulses
                pulse_count += 1
                last_event_time = now
        
        if pulse_count > 0 and (now - last_event_time) > ACCUMULATION_WINDOW:
            if not is_lid_closed():
                # GHOST FILTER: Real buttons on this model send 2-4 pulses per tap.
                # Every 2 pulses is roughly 1 physical tap.
                if pulse_count >= 2:
                    click_count = max(1, pulse_count // 2)
                    if click_count == 1: run_cmd(CMD_SNIP)
                    elif click_count == 2: run_cmd(CMD_GEMINI)
                    elif click_count >= 3: run_cmd(CMD_UPDATE)
            
            pulse_count = 0
            
        if p.poll() is not None:
            sys.exit(1)

if __name__ == "__main__":
    main()
