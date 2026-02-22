#!/bin/bash
#
# Build LAME MP3 Encoder for Android
# Required by FFmpeg for MP3 encoding
#
# Usage:
#   ./build-lame.sh [arm64|arm|both]
#

set -e

# Configuration
ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$HOME/Library/Android/sdk/ndk/27.0.12077973}"
BUILD_ROOT="${BUILD_ROOT:-$HOME/work-dir/ffmpeg-minimal-build}"
LAME_VERSION="3.100"
LAME_SRC="$BUILD_ROOT/lame-$LAME_VERSION"
LAME_PREFIX="$BUILD_ROOT/lame-install"
API_LEVEL=26
BUILD_ARCH="${1:-both}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }

# Check NDK
if [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "❌ Error: Android NDK not found"
    exit 1
fi

TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64"

# Create directories
mkdir -p "$BUILD_ROOT"
cd "$BUILD_ROOT"

# Download LAME source
if [ ! -d "$LAME_SRC" ]; then
    log_info "Downloading LAME $LAME_VERSION..."
    wget -q "https://sourceforge.net/projects/lame/files/lame/$LAME_VERSION/lame-$LAME_VERSION.tar.gz"
    tar xzf "lame-$LAME_VERSION.tar.gz"
    rm "lame-$LAME_VERSION.tar.gz"
    log_success "LAME source downloaded"
fi

build_lame_for_arch() {
    local ARCH=$1
    local ABI=$2
    
    log_info "Building LAME for $ABI..."
    
    # Set toolchain
    if [ "$ARCH" = "arm64" ]; then
        export CC="$TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang"
        export AR="$TOOLCHAIN/bin/llvm-ar"
        export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
        HOST="aarch64-linux-android"
    else
        export CC="$TOOLCHAIN/bin/armv7a-linux-androideabi${API_LEVEL}-clang"
        export AR="$TOOLCHAIN/bin/llvm-ar"
        export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
        HOST="armv7a-linux-androideabi"
    fi
    
    PREFIX="$LAME_PREFIX/$ABI"
    BUILD_DIR="$BUILD_ROOT/lame-build-$ABI"
    
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Configure (static only - FFmpeg will link it statically)
    "$LAME_SRC/configure" \
        --prefix="$PREFIX" \
        --host="$HOST" \
        --disable-shared \
        --enable-static \
        --disable-frontend \
        --disable-analyzer-hooks \
        --disable-gtktest \
        CFLAGS="-O3 -fPIC"
    
    # Build
    make -j$(sysctl -n hw.ncpu)
    make install
    
    log_success "LAME built for $ABI (static library: $(du -h "$PREFIX/lib/libmp3lame.a" 2>/dev/null | awk '{print $1}' || echo 'built'))"
}

# Build for requested architectures
if [ "$BUILD_ARCH" = "arm64" ] || [ "$BUILD_ARCH" = "both" ]; then
    build_lame_for_arch "arm64" "arm64-v8a"
fi

if [ "$BUILD_ARCH" = "arm" ] || [ "$BUILD_ARCH" = "both" ]; then
    build_lame_for_arch "arm" "armeabi-v7a"
fi

log_success "LAME build complete!"
