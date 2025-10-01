#!/bin/bash
# Verificación post-upgrade para Pop!_OS con LUKS + LVM + teclado USB

KERNEL=$(uname -r)
INITRD="/boot/initrd.img-$KERNEL"
LOGDIR="$HOME/postupgrade-logs"
LOGFILE="$LOGDIR/check-$(date +'%Y%m%d-%H%M%S').log"

mkdir -p "$LOGDIR"

# Variable para estado global
STATUS=0

{
  echo "=== Verificando initramfs para kernel $KERNEL ==="

  # 1. Verificar hooks críticos
  for item in cryptroot lvm2; do
    if lsinitramfs "$INITRD" | grep -q "$item"; then
      echo "[OK] $item presente en initramfs"
    else
      echo "[FAIL] $item NO encontrado en initramfs"
      STATUS=1
    fi
  done

  # 2. Verificar binarios/módulos esenciales
  for item in cryptsetup lvm usbhid; do
    if lsinitramfs "$INITRD" | grep -q "$item"; then
      echo "[OK] $item presente en initramfs"
    else
      echo "[FAIL] $item NO encontrado en initramfs"
      STATUS=1
    fi
  done

  # 3. Confirmar sincronización con ESP mediante kernelstub
  echo "=== Verificando kernelstub ==="
  KS_OUTPUT=$(sudo kernelstub -v 2>&1)

  if echo "$KS_OUTPUT" | grep -q "Copying"; then
    echo "[OK] kernelstub reportó copia al ESP"
  else
    echo "[WARN] kernelstub no mostró mensajes de copia al ESP"
    STATUS=1
  fi

  # 4. Revisar mensajes de arranque recientes
  echo "=== Revisando dmesg (crypt|lvm) ==="
  DMESG_OUTPUT=$(sudo dmesg -T | grep -E "crypt|lvm" | tail -n 10)
  echo "$DMESG_OUTPUT"

  # Resumen final
  if [ $STATUS -eq 0 ]; then
    echo ">>> Estado general: OK ✅"
  else
    echo ">>> Estado general: FAIL ⚠️"
  fi

} | tee "$LOGFILE"

echo ">>> Log guardado en: $LOGFILE"
