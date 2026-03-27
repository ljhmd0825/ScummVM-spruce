#!/bin/bash
set -e

SCUMMVM_VERSION="${SCUMMVM_VERSION:-v2026.1.0}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"

echo "=== Building ScummVM ${SCUMMVM_VERSION} for aarch64 (universal 64-bit) ==="

# Clone ScummVM
if [ ! -d "scummvm" ]; then
    git clone --depth 1 --branch "$SCUMMVM_VERSION" \
        https://github.com/scummvm/scummvm.git
fi

cd scummvm

# Apply patches
for dir in /patches/common /patches/64; do
    if [ -d "$dir" ] && ls "$dir"/*.patch 1>/dev/null 2>&1; then
        for patch in "$dir"/*.patch; do
            echo "Applying: $(basename "$patch")"
            git apply "$patch"
        done
    fi
done

# Apply Python patches
for dir in /patches/common /patches/64; do
    if [ -d "$dir" ] && ls "$dir"/*.py 1>/dev/null 2>&1; then
        for patch in "$dir"/*.py; do
            echo "Applying: $(basename "$patch")"
            python3 "$patch"
        done
    fi
done

# Cross-compilation environment
export CC="ccache aarch64-linux-gnu-gcc"
export CXX="ccache aarch64-linux-gnu-g++"
export AR="aarch64-linux-gnu-ar"
export STRIP="aarch64-linux-gnu-strip"
export PKG_CONFIG_PATH="/usr/lib/aarch64-linux-gnu/pkgconfig"
export PKG_CONFIG_LIBDIR="/usr/lib/aarch64-linux-gnu/pkgconfig"
export CCACHE_DIR="${CCACHE_DIR:-/ccache}"

# Configure for universal 64-bit: SDL2 + OpenGL ES2, all engines

./configure \
    --host=aarch64-linux-gnu \
    --backend=sdl \
    --opengl-mode=gles2 \
    --enable-all-engines \
    --enable-optimizations \
    --enable-release \
    --enable-vkeybd \
    --enable-fluidsynth \
    --enable-neon \
    --enable-cloud \
    --enable-enet | tee configure_summary.txt

#  Build
make -j$(nproc)

# Output
echo "=== Copying Binary and Build Logs ==="
mkdir -p "$OUTPUT_DIR/logs"

#
cp scummvm "$OUTPUT_DIR/scummvm.64"
$STRIP "$OUTPUT_DIR/scummvm.64"

#
cp config.h "$OUTPUT_DIR/logs/config.h"
cp config.log "$OUTPUT_DIR/logs/config.log"
cp config.mk "$OUTPUT_DIR/logs/config.mk"
cp configure_summary.txt "$OUTPUT_DIR/logs/summary.txt"

echo "=== Done! Check /output/scummvm.64 and /output/logs/ ==="
