# Building from source

The source revisions, toolchain, and expected kernel release are recorded in [`SOURCES.lock`](../SOURCES.lock). The kernel build checks out NVIDIA's pinned 9.2.2 open-source commits. Run the kernel commands below from the repository root on Linux.

## Kernel

Install Git, the standard Linux kernel build dependencies, Android Clang `r416183b`, and an AArch64 GNU cross-toolchain. The script expects the `aarch64-linux-gnu-` tools on `PATH` unless `CROSS_COMPILE` is set to another prefix.

Obtain the running configuration from a Shield on Shield Experience 9.2.4:

```bash
adb exec-out cat /proc/config.gz > config.gz
```

Then choose a new path that does not already exist for `WORK_DIR`:

```bash
export CLANG_BIN=/path/to/clang-r416183b/bin
export SHIELD_CONFIG=/path/to/config.gz
export WORK_DIR=/path/to/new-work-directory
PROFILE=cpu-gpu-emc ./scripts/build.sh
```

Available profiles:

| Profile | Clock patches |
| --- | --- |
| `baseline` | None |
| `cpu` | CPU |
| `cpu-gpu` | CPU and GPU |
| `cpu-gpu-emc` | CPU, GPU, and RAM/EMC |

The compiled raw kernel is written to `$WORK_DIR/out/arch/arm64/boot/Image`. Do not flash the raw `Image` directly to the boot partition.

## Boot image

Repack the kernel into a matching Shield 9.2.4 `LNX`/boot image with `magiskboot`:

```bash
STOCK_BOOT=/path/to/stock-boot.img \
MAGISKBOOT=/path/to/magiskboot \
KERNEL_IMAGE="$WORK_DIR/out/arch/arm64/boot/Image" \
OUTPUT=/path/to/Shield-OC.img \
./scripts/repack.sh
```

For a rooted image, use a boot image already patched by Magisk and enable the Shield LegacySAR adjustment:

```bash
STOCK_BOOT=/path/to/magisk-patched-boot.img \
MAGISKBOOT=/path/to/magiskboot \
KERNEL_IMAGE="$WORK_DIR/out/arch/arm64/boot/Image" \
OUTPUT=/path/to/Shield-OC.img \
MAGISK_LEGACY_SAR=1 \
./scripts/repack.sh
```

Test the completed boot image with `fastboot boot` before writing it to the boot partition.

## Shield Tools

Install JDK 17, Android SDK 35, Gradle, and Apktool. Obtain Rootfan's Shield Tools 1.4 APK from the linked XDA thread, then run on Windows:

```powershell
.\scripts\build-app.ps1 -BaseApk .\Shield_Tools_V1_4.apk -OutputApk .\Shield-Tools-1.5-unsigned.apk
```

Use `-Gradle path\to\gradle` if Gradle is not on `PATH`. The result is unsigned and must be signed with your own Android signing key.
