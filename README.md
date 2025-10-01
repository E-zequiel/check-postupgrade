# check-postupgrade
---
## Introduction and origin

This script was born after a boot incident in `Pop!_OS` where the system stopped asking for the LUKS password, “waited” for the encrypted volume, and ended up in BusyBox (initramfs) without recognizing the USB keyboard. The issue was resolved by aligning kernel parameters, regenerating the initramfs, and synchronizing the ESP, confirming that the failure was in the early boot chain (LUKS unlock, LVM activation, images/flags in the ESP).
The goal of check-postupgrade is to audit, after each update and before reboot, the critical points that can break the boot: effective kernel parameters, initramfs contents, fstab/crypttab consistency, and ESP/boot entries state. With this quick and traceable verification, inconsistencies that lead to emergency mode or BusyBox are prevented.
Although the script was originally created after a `Pop!_OS` boot incident, it is now portable and works on other Linux distributions (Ubuntu, Debian, Arch, Fedora, etc.).

---
## Summary of the incident that motivated the script

- **Main symptom:** The LUKS prompt did not appear; the kernel “waited” for the encrypted device and dropped to BusyBox.
- **Additional limitation:** USB keyboard unresponsive in initramfs, preventing interaction.
- **Detected causes:** Incomplete or outdated boot parameters (`root=UUID`, `rd.luks.name`), initramfs missing critical modules/hooks or out of sync, and ESP with old images/entries.
- **Corrective actions:** Regeneration of initramfs, parameter adjustment with kernelstub, and verification of fstab/crypttab and ESP contents. After this, the system booted normally again.

---
## Usage

**Recommended location:** `~/.scripts/check-postupgrade` with symlink to `~/.local/bin/checkpost`.  
**Typical execution:** After each system or kernel update, before reboot if possible.
```bash
checkpost
```

---
## Script walkthrough (block by block)

This script is designed to verify the integrity of the boot chain after a system upgrade on Linux distributions using LUKS, LVM, and an EFI System Partition (ESP). Here’s what each block does:

1. **Verify critical hooks in initramfs**
    - Checks for the presence of `cryptroot` and `lvm2` inside the initramfs image.
    - These hooks are essential for unlocking encrypted volumes and activating logical volumes during early boot.
2. **Verify essential binaries/modules in initramfs**
    - Confirms that `cryptsetup`, `lvm`, `usbhid`, and `usbkbd` are included.
    - Without these, the system may fail to unlock encrypted partitions or recognize USB keyboards at the initramfs stage.
3. **Verify kernel command line parameters**
    - Extracts the kernel command line from `dmesg`.
    - Ensures that both `root=UUID=<...>` and `rd.luks.name=<UUID>=cryptdata` are present.
    - These parameters tell the kernel which device to mount as root and how to map the encrypted volume.
4. **Confirm ESP synchronization (`Pop!_OS-specific`)**
    - If `kernelstub` is available, runs it in verbose mode.
    - Looks for “Copying” messages to confirm that the kernel and initramfs were copied into the ESP.
    - If `kernelstub` is not installed (other distros), this step is skipped automatically.
5. **List files in the ESP**
    - Uses a portable `find` command to display files under `/boot/efi/EFI/*`.
    - If `/boot/efi` is not mounted, the script shows a warning instead of failing.
    - This provides visibility into what kernel and initramfs images are actually stored in the EFI partition, regardless of distro-specific layout.
6. **Validate fstab/crypttab consistency**
    - Prints relevant entries from `/etc/crypttab` and `/etc/fstab`.
    - Ensures that UUIDs and PARTUUIDs match the devices actually used by the system.
    - Prevents boot failures caused by mismatched or outdated identifiers.
7. **Review recent dmesg messages (crypt|lvm)**
    - Shows the last 10 kernel log entries related to cryptsetup or LVM.
    - Useful for spotting recent errors or warnings during boot.
8. **Final summary**
    - If all checks pass, prints `Overall status: OK ✅`.
    - If any check fails, prints `Overall status: FAIL ⚠️`.
    - All output is saved to a timestamped log file in `~/postupgrade-logs/`.

---
## Interpreting the output

The script produces a structured report. Here’s how to read it and what to do if problems are detected:

- **`[OK]` messages**
    - Everything is in place. No action required.
- **`[FAIL]` messages**
    - Indicates a missing hook, binary, or kernel parameter.
    - **Action:**
        - If initramfs is missing items → regenerate with `sudo update-initramfs -u -k all` (Debian/Ubuntu/Pop!_OS) or the equivalent for your distro.
        - If kernel command line is missing parameters → adjust bootloader configuration (e.g., `kernelstub`, `grub.cfg`, or `loader.conf`) and re-sync the ESP.
- **`[WARN]` messages**
    - Something is unusual but not necessarily fatal.
    - Examples: kernelstub not found (expected on non-`Pop!_OS` distros), `/boot/efi` not mounted, ESP files not found under `/boot/efi/EFI/*` (may be normal if the distro uses `/boot/efi/loader/entries`), or no matching entries in `crypttab`.
    - **Action:** Review whether this is expected for your setup. If not, investigate further.
- **ESP file listing empty**
    - If no files are shown under `/boot/efi/EFI/*`, it may mean the ESP is not mounted or the files are stored in a different path (e.g., `/boot/efi/loader/entries`).
    - **Action:** Mount the ESP manually and confirm its contents.
- **dmesg errors**
    - If the last lines show failures to unlock LUKS devices or activate LVM, the system may fail to boot after the next update.
    - **Action:** Investigate UUIDs in `crypttab`/`fstab`, check for corrupted volumes, and ensure initramfs includes the required modules.
- **Final summary (`Overall status: FAIL ⚠️`)**
    - At least one critical check failed.
    - **Action:** Review the log file saved in `~/postupgrade-logs/` for details, correct the issue, and re-run the script until the status is `OK ✅`.

---
## Maintenance and best practices

- **Periodicity:** Run after each kernel/system update, before reboot if possible.
- **Traceability:** Keep logs in `~/postupgrade-logs/` for comparison in case of incidents.
- **It adapts automatically:** if `kernelstub` is not present, that check is skipped; if `/etc/crypttab` is missing, the script continues without error.
- **Additional robustness:**
	- **Clear lead-in labels in fstab:** keep `nofail` and timeouts for non-essential devices.
	- **ESP verification:** check entries under `/boot/efi/EFI/*` after kernel changes.
	- **Automation:** integrate the script into the post-update flow to guarantee consistency.

---
## Conclusion

This script is intended to be run after operating system upgrades, before rebooting the PC, in order to audit the early boot chain and confirm alignment between kernel parameters, initramfs, and ESP, thus avoiding failed reboots. With it you gain control, clarity, and a useful history for diagnosis.

