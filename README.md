# Shield Overclock

CPU, GPU, and EMC overclock patches for Shield Experience 9.2.4 on the original Tegra X1 Shield TV.

Supported models:

- 2015 Shield TV 16 GB (`foster`)
- 2015 Shield TV Pro 500 GB (`foster`)
- 2017 Shield TV 16 GB (`darcy`)
- 2017 Shield TV Pro 500 GB (`foster`)

The 2019 Shield TV Pro (`mdarcy`) and 2019 Shield TV (`sif`) are not supported.

Download `Shield-OC.img`, `Shield-OC-Image`, and `Shield-Tools-1.5.apk` from the [v1.9 release](https://github.com/forkymcforkface/shield-overclock/releases/tag/v1.9). `Shield-OC.img` is the complete Magisk-compatible boot image. `Shield-OC-Image` is the raw kernel for building a boot image with `scripts/repack.sh`. Shield Tools requires Magisk root.

## Default behavior without root

- CPU maximum: 2218.5 MHz; governor: `schedutil`
- GPU maximum: 1228.8 MHz; governor: `nvhost_podgov`
- RAM/EMC maximum: 1866 MHz
- Fan: Auto

These are dynamic maximums, not fixed clocks. Root and Shield Tools are only needed to change and save different selections.

Factory maximums are 2014.5 MHz CPU, 998.4 MHz GPU, and 1600 MHz RAM/EMC. Shield Tools marks each factory choice in its selection list.

## Before you begin

- Install the [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools).
- Download `Shield-OC.img` and place it in the Platform Tools folder.
- Download and install the [Magisk app](https://github.com/topjohnwu/Magisk/releases) on the Shield. The release boot image contains the Magisk boot components; the app manages and approves root access for the backup command and Shield Tools.
- Enable USB debugging on the Shield and connect it to the computer by USB.
- [Unlock the bootloader](https://gitlab.com/nvidia/nv-tegra/manifest/android/binary/-/blob/rel-24-uda-r1.4-partner/README_SHIELD?ref_type=heads#flashing-the-shield-device) if it is still locked. This only needs to be done once.

Warning: Unlocking the bootloader erases all user data. Complete the initial Shield setup and enable USB debugging again afterward.

## Temporarily booting the image

1. On the computer, open a command prompt or terminal in the Platform Tools folder.
2. Reboot the Shield into fastboot mode:

   ```text
   adb -d reboot bootloader
   ```

3. Verify that the computer detects the Shield:

   ```text
   fastboot devices
   ```

4. Boot the image without writing it to the Shield:

   ```text
   fastboot boot Shield-OC.img
   ```

A normal reboot returns to the installed kernel.

## Backing up the stock boot image

While temporarily booted, copy the unchanged stock `LNX` partition to the computer:

```text
adb -d shell su -c "dd if=/dev/block/by-name/LNX of=/sdcard/stock-boot.img bs=4M"
adb -d pull /sdcard/stock-boot.img stock-boot.img
```

Approve the root request on the Shield if prompted. Confirm that `stock-boot.img` exists on the computer and keep it somewhere safe before continuing.

## Installing the image

Only continue after the exact image boots successfully and the stock boot image has been backed up.

1. Reboot the Shield into fastboot mode:

   ```text
   adb -d reboot bootloader
   ```

2. Verify that the computer detects the Shield:

   ```text
   fastboot devices
   ```

3. Write the image to the boot partition and reboot:

   ```text
   fastboot flash boot Shield-OC.img
   fastboot reboot
   ```

This is the method used on the tested 2017 Pro.

To restore the stock boot image, enter fastboot mode and run:

```text
fastboot flash boot stock-boot.img
fastboot reboot
```

To compile the kernel or Shield Tools yourself, see [Building from source](patches/README.md).

NVIDIA publishes the [Shield open-source packages and recovery images](https://developer.nvidia.com/shield-open-source). This work builds on Rootfan's [XDA thread](https://xdaforums.com/t/kernel-9-1-performance-enhanced-overclock-kernel.3943079/) and [kernel repository](https://github.com/rootfan/tegra-linux-4.9).
