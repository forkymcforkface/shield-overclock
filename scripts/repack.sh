#!/usr/bin/env bash
set -euo pipefail

: "${STOCK_BOOT:?Set STOCK_BOOT to a stock 9.2.4 LNX image}"
: "${MAGISKBOOT:?Set MAGISKBOOT to a local magiskboot executable}"
: "${KERNEL_IMAGE:?Set KERNEL_IMAGE to the built Image}"
: "${OUTPUT:?Set OUTPUT to the desired boot image path}"

magisk_legacy_sar="${MAGISK_LEGACY_SAR:-0}"
if [[ "$magisk_legacy_sar" != 0 && "$magisk_legacy_sar" != 1 ]]; then
  echo "MAGISK_LEGACY_SAR must be 0 or 1" >&2
  exit 2
fi

stock_boot="$(realpath "$STOCK_BOOT")"
magiskboot="$(realpath "$MAGISKBOOT")"
kernel_image="$(realpath "$KERNEL_IMAGE")"
output="$(realpath -m "$OUTPUT")"
temp_dir="$(mktemp -d)"
trap 'rm -rf -- "$temp_dir"' EXIT

cp "$stock_boot" "$temp_dir/boot.img"
cp "$magiskboot" "$temp_dir/magiskboot"
cp "$kernel_image" "$temp_dir/built-Image"
chmod +x "$temp_dir/magiskboot"

cd "$temp_dir"
./magiskboot unpack boot.img
cp built-Image kernel
if [[ "$magisk_legacy_sar" == 1 ]]; then
  if [[ ! -s ramdisk.cpio ]]; then
    echo "MAGISK_LEGACY_SAR=1 requires a Magisk-patched input boot image" >&2
    exit 2
  fi
  ./magiskboot hexpatch kernel 736b69705f696e697472616d667300 77616e745f696e697472616d667300
fi
./magiskboot repack boot.img new-boot.img
cp new-boot.img "$output"
sha256sum "$output"
