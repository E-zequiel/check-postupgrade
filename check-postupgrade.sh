#!/bin/bash
# Post-upgrade verification for Linux systems with LUKS + LVM + USB keyboard
# Designed for Pop!_OS but portable to other distros

KERNEL=$(uname -r)
INITRD="/boot/initrd.img-$KERNEL"
LOGDIR="$HOME/postupgrade-logs"
LOGFILE="$LOGDIR/check-$(date +'%Y%m%d-%H%M%S').log"

mkdir -p "$LOGDIR"

STATUS=0

{
  echo "=== Post-upgrade verification for kernel $KERNEL ==="

  # 1. Verify critical hooks in initramfs
  for item in cryptroot lvm2; do
    if lsinitramfs "$INITRD" 2>/dev/null | grep -q "$item"; then
      echo "[OK] $item present in initramfs"
    else
      echo "[FAIL] $item NOT found in initramfs"
      STATUS=1
    fi
  done

  # 2. Verify essential binaries/modules in initramfs
  for item in cryptsetup lvm usbhid usbkbd; do
    if lsinitramfs "$INITRD" 2>/dev/null | grep -q "$item"; then
      echo "[OK] $item present in initramfs"
    else
      echo "[FAIL] $item NOT found in initramfs"
      STATUS=1
    fi
  done

  # 3. Verify kernel command line parameters
  echo "=== Checking kernel command line ==="
  CMDLINE=$(sudo dmesg | grep "Kernel command line")
  echo "$CMDLINE"
  if echo "$CMDLINE" | grep -q "root=UUID=" && echo "$CMDLINE" | grep -q "rd.luks.name="; then
    echo "[OK] Kernel command line contains root=UUID and rd.luks.name"
  else
    echo "[WARN] Kernel command line missing root=UUID or rd.luks.name"
    STATUS=1
  fi

  # 4. Confirm ESP synchronization (only if kernelstub exists)
  if command -v kernelstub >/dev/null 2>&1; then
    echo "=== Checking kernelstub ==="
    KS_OUTPUT=$(sudo kernelstub -v 2>&1)
    echo "$KS_OUTPUT"
    if echo "$KS_OUTPUT" | grep -q "Copying"; then
      echo "[OK] kernelstub reported copy to ESP"
    else
      echo "[WARN] kernelstub did not show copy messages to ESP"
      STATUS=1
    fi
  else
    echo "[INFO] kernelstub not found (skipping Pop!_OS-specific check)"
  fi

  # 5. List files in ESP (portable)
  if mount | grep -q "/boot/efi"; then
    echo "=== Files in ESP (/boot/efi/EFI/*) ==="
    sudo find /boot/efi/EFI -maxdepth 2 -type f -print 2>/dev/null || echo "[WARN] No EFI files found"
  else
    echo "[WARN] /boot/efi not mounted, skipping ESP file listing"
  fi

  # 6. Validate fstab/crypttab consistency
  if [ -f /etc/crypttab ]; then
    echo "=== Relevant entries in crypttab ==="
    grep -E "cryptdata|UUID=" /etc/crypttab || echo "[WARN] No matching entries found"
  else
    echo "[INFO] /etc/crypttab not present on this system"
  fi

  if [ -f /etc/fstab ]; then
    echo "=== Relevant entries in fstab ==="
    grep -E "UUID=|PARTUUID=" /etc/fstab || echo "[WARN] No matching entries found"
  else
    echo "[INFO] /etc/fstab not present on this system"
  fi

  # 7. Review recent dmesg messages (crypt|lvm)
  echo "=== Recent dmesg entries (crypt|lvm) ==="
  sudo dmesg -T | grep -E "crypt|lvm" | tail -n 10

  # Final summary
  if [ $STATUS -eq 0 ]; then
    echo ">>> Overall status: OK ✅"
  else
    echo ">>> Overall status: FAIL ⚠️"
  fi

} | tee "$LOGFILE"

echo ">>> Log saved to: $LOGFILE"
