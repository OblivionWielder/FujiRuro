# Fujitsu STYLISTIC Q5010 BIOS Update & Stability Investigation

This repository includes this guide to ensure that the Fujitsu Q5010 (and similar Gemini Lake models) can achieve full hardware stability on Linux.

## 1. The Linux Hardware Challenge
Out of the box, even with modern kernels (6.12+), the Q5010 often exhibits critical sensor failures.

### The "Dying Sensor" Symptom
If your `dmesg` looks like this:
```text
[   10.453211] intel-ishtp-hid ... ishtp: device timeout during init
[   15.561002] i2c_hid_acpi i2c-FTSC1000:00: incomplete report
```
Your BIOS (likely v1.20) is preventing the **Intel Sensor Hub (ISH)** from initializing. This breaks:
- Automatic Screen Rotation (Accelerometer)
- Adaptive Brightness (ALS)
- Touchscreen responsiveness (Timing mismatches)

## 2. The Solution: BIOS v1.39
Updating to the April 2025 firmware (v1.39) is **mandatory** for a stable nomadic setup.

### Mandatory Intermediate Step: v1.28
Fujitsu documentation states you **MUST** flash BIOS **v1.28** before moving to v1.39 if your current version is older. Failure to do so may result in a bricked device.

## 3. EFI Shell Flashing (No Windows Required)
We use a standalone EFI flasher to update the system directly from a USB drive.

### Preparation
1. **Drive:** Format a USB stick as FAT32 with a GPT partition table.
2. **Tools:** Obtain `EfiFlash.efi` (Kontron/Fujitsu industrial flasher).
3. **Capsules:** Extract `FJNBC13.CAP` from the Fujitsu BIOS Admin Packs for both v1.28 and v1.39.
4. **BIOS Config:** Set "Advanced" -> "Flash BIOS" to **Allowed** and disable **Secure Boot**.

### Step-by-Step
1. Boot to the EFI Shell via the F12 Boot Menu.
2. Navigate to your USB drive (e.g., `fs0:`).
3. **Flash v1.28:** `.\EfiFlash.efi FJNBC13.CAP` (Verify it's the 1.28 file).
4. Reboot and verify version.
5. **Flash v1.39:** `.\EfiFlash.efi FJNBC13.CAP` (The 1.39 file).
6. Final reboot.

## 4. Stability Verification
After the update, check your logs:
```bash
dmesg | grep ishtp
```
You should see successful initialization of the HID clients. Your screen rotation and ambient light sensors will now work natively with `iio-sensor-proxy`.

## 5. Sources & Resources
- **Official Support:** [Fujitsu Global BIOS Search](https://support.ts.fujitsu.com/)
- **Industrial Flasher:** Sourced from the Kontron/Fujitsu Industrial motherboard support FTP.
- **Local Cache:** Check `~/Downloads/` for the original ZIP packages used in this investigation.
