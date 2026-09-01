#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

: "${CLANG_BIN:?Set CLANG_BIN to Android clang r416183b bin directory}"
: "${SHIELD_CONFIG:?Set SHIELD_CONFIG to the target Shield config or config.gz}"
: "${WORK_DIR:?Set WORK_DIR to a new, nonexistent work directory}"

profile="${PROFILE:-baseline}"
cross_compile="${CROSS_COMPILE:-aarch64-linux-gnu-}"
jobs="${JOBS:-$(nproc)}"

if [[ -e "$WORK_DIR" ]]; then
  echo "Refusing to reuse existing WORK_DIR: $WORK_DIR" >&2
  exit 2
fi
if [[ ! -x "$CLANG_BIN/clang" ]]; then
  echo "clang is not executable at $CLANG_BIN/clang" >&2
  exit 2
fi
if [[ "$profile" != baseline && "$profile" != cpu && "$profile" != cpu-gpu && "$profile" != cpu-gpu-emc ]]; then
  echo "PROFILE must be baseline, cpu, cpu-gpu, or cpu-gpu-emc" >&2
  exit 2
fi
mkdir -p "$WORK_DIR"
core="$WORK_DIR/linux-4.9"
nvidia="$WORK_DIR/nvidia"
nvgpu="$WORK_DIR/nvgpu"
out="$WORK_DIR/out"

git clone --no-checkout https://gitlab.com/nvidia/nv-tegra/linux-4.9.git "$core"
git -C "$core" checkout --detach e7d2f8cc12ddadad5664014cc79eeb528a65646a
git clone --no-checkout https://gitlab.com/nvidia/nv-tegra/linux-nvidia.git "$nvidia"
git -C "$nvidia" checkout --detach 0c6601439a7248857325e3c576ebee33f2c8601b
git clone --no-checkout https://gitlab.com/nvidia/nv-tegra/linux-nvgpu.git "$nvgpu"
git -C "$nvgpu" checkout --detach 9fc87a7ec7b87ac40ccf8f81896c6da755ffc9f8

git -C "$nvgpu" apply "$repo_root/patches/linux-nvgpu/0001-build-integrated-nvgpu-into-kernel.patch"
if [[ "$profile" == cpu || "$profile" == cpu-gpu || "$profile" == cpu-gpu-emc ]]; then
  git -C "$core" apply "$repo_root/patches/linux-4.9/0001-shield-port-2.22-GHz-CPU-overclock.patch"
  git -C "$nvidia" apply "$repo_root/patches/linux-nvidia/0001-shield-complete-2.22-GHz-CPU-overclock.patch"
fi
if [[ "$profile" == cpu-gpu || "$profile" == cpu-gpu-emc ]]; then
  git -C "$nvidia" apply "$repo_root/patches/linux-nvidia/0001-1.23-GHz-GPU-overclock.patch"
fi
if [[ "$profile" == cpu-gpu-emc ]]; then
  git -C "$core" apply --unidiff-zero "$repo_root/patches/linux-4.9/0002-shield-safe-1.866-GHz-EMC-overclock.patch"
fi

mkdir -p "$out"
if gzip -t "$SHIELD_CONFIG" 2>/dev/null; then
  gzip -dc "$SHIELD_CONFIG" > "$out/.config"
else
  cp "$SHIELD_CONFIG" "$out/.config"
fi

"$core/scripts/config" --file "$out/.config" --set-str LOCALVERSION "-tegra+"
"$core/scripts/config" --file "$out/.config" --disable LOCALVERSION_AUTO
"$core/scripts/config" --file "$out/.config" --set-str SYSTEM_TRUSTED_KEYS ""

export PATH="$CLANG_BIN:$PATH"
export KERNEL_OVERLAYS="$nvidia:$nvgpu"
export KBUILD_BUILD_USER="${KBUILD_BUILD_USER:-shield-builder}"
export KBUILD_BUILD_HOST="${KBUILD_BUILD_HOST:-reproducible}"

make_args=(
  "O=$out"
  ARCH=arm64
  CC=clang
  "CROSS_COMPILE=$cross_compile"
  LOCALVERSION=
)

if [[ -n "${HOST_DEPS_PREFIX:-}" ]]; then
  make_args+=(
    "HOSTCFLAGS=-I$HOST_DEPS_PREFIX/include -I$HOST_DEPS_PREFIX/include/x86_64-linux-gnu"
    "HOST_LOADLIBES=-L$HOST_DEPS_PREFIX/lib/x86_64-linux-gnu"
  )
  export LD_LIBRARY_PATH="$HOST_DEPS_PREFIX/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

make -C "$core" "${make_args[@]}" olddefconfig
make -C "$core" -j"$jobs" "${make_args[@]}" Image

release="$(cat "$out/include/config/kernel.release")"
if [[ "$release" != 4.9.141-tegra+ ]]; then
  echo "Unexpected kernel release: $release" >&2
  exit 3
fi

sha256sum "$out/arch/arm64/boot/Image"
echo "Built profile '$profile': $out/arch/arm64/boot/Image"
