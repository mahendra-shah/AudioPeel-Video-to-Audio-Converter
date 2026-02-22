#!/bin/bash
#
# Build Minimal FFmpeg for Android (AudioPeel)
# Reduces FFmpeg from ~110MB to ~7MB per ABI
#
# This script builds FFmpeg with ONLY the codecs and features needed:
# - Video decoders (to read video files)
# - MP3 encoder (to write MP3 files)
# - Basic demuxers (to parse video containers)
# - loudnorm filter (for volume normalization)
#
# Usage:
#   ./build-ffmpeg-minimal.sh [arm64|arm|both]
#
# Examples:
#   ./build-ffmpeg-minimal.sh arm64    # Build for 64-bit only
#   ./build-ffmpeg-minimal.sh both     # Build for both architectures (recommended)
#

set -e  # Exit on any error

# ============================================================================
# CONFIGURATION
# ============================================================================

# Android NDK path (update if yours is different)
ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$HOME/Library/Android/sdk/ndk/27.0.12077973}"
if [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "❌ Error: Android NDK not found at: $ANDROID_NDK_HOME"
    echo "Please install NDK via Android Studio SDK Manager or set ANDROID_NDK_HOME variable"
    exit 1
fi

# Build directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ROOT="${BUILD_ROOT:-$HOME/work-dir/ffmpeg-minimal-build}"
FFMPEG_SRC="$BUILD_ROOT/ffmpeg"
LAME_PREFIX="$BUILD_ROOT/lame-install"

# API level (Android 8.0+, matches your minSdk: 26)
API_LEVEL=26

# Architecture to build (arm64, arm, or both)
BUILD_ARCH="${1:-both}"

# ============================================================================
# COLORS FOR OUTPUT
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ============================================================================
# STEP 1: SETUP & VALIDATION
# ============================================================================

log_section "Step 1: Environment Setup & Validation"

# Create build directories
log_info "Creating build directories..."
mkdir -p "$BUILD_ROOT"
cd "$BUILD_ROOT"
log_success "Build directory: $BUILD_ROOT"

# Check required tools
log_info "Checking required build tools..."
REQUIRED_TOOLS="autoconf automake libtool pkg-config wget nasm yasm"
MISSING_TOOLS=""

for tool in $REQUIRED_TOOLS; do
    if ! command -v $tool &> /dev/null; then
        MISSING_TOOLS="$MISSING_TOOLS $tool"
    fi
done

if [ -n "$MISSING_TOOLS" ]; then
    log_error "Missing required tools:$MISSING_TOOLS"
    log_info "Install them with: brew install$MISSING_TOOLS"
    exit 1
fi
log_success "All required tools found"

# Validate NDK
log_info "Validating Android NDK..."
TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64"
if [ ! -d "$TOOLCHAIN" ]; then
    log_error "NDK toolchain not found at: $TOOLCHAIN"
    exit 1
fi
log_success "NDK validated: $ANDROID_NDK_HOME"

# ============================================================================
# STEP 2: DOWNLOAD FFMPEG SOURCE
# ============================================================================

log_section "Step 2: Download FFmpeg Source Code"

if [ ! -d "$FFMPEG_SRC" ]; then
    log_info "Cloning FFmpeg (this may take 5-10 minutes)..."
    git clone --depth 1 --branch n5.1 https://git.ffmpeg.org/ffmpeg.git "$FFMPEG_SRC"
    log_success "FFmpeg source downloaded"
else
    log_warning "FFmpeg source already exists, skipping download"
fi

# ============================================================================
# STEP 3: BUILD LAME MP3 ENCODER
# ============================================================================

log_section "Step 3: Build LAME MP3 Encoder Library"

if [ ! -d "$LAME_PREFIX" ]; then
    log_info "Building LAME library (this is required for MP3 encoding)..."
    
    # Check if build-lame.sh exists
    if [ -f "$SCRIPT_DIR/build-lame.sh" ]; then
        bash "$SCRIPT_DIR/build-lame.sh" "$BUILD_ARCH"
        log_success "LAME library built successfully"
    else
        log_error "build-lame.sh not found. Please run it first."
        exit 1
    fi
else
    log_warning "LAME library already exists, skipping build"
fi

# ============================================================================
# STEP 4: BUILD FFMPEG FOR EACH ARCHITECTURE
# ============================================================================

build_ffmpeg_for_arch() {
    local ARCH=$1
    local ABI=$2
    local TARGET=$3
    
    log_section "Step 4.$ARCH: Building FFmpeg for $ABI"
    
    # Set architecture-specific variables
    if [ "$ARCH" = "arm64" ]; then
        export CC="$TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang"
        export CXX="$TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang++"
        export AR="$TOOLCHAIN/bin/llvm-ar"
        export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
        export STRIP="$TOOLCHAIN/bin/llvm-strip"
        export LD="$TOOLCHAIN/bin/ld.lld"
        ARCH_FLAGS="--arch=aarch64 --cpu=armv8-a --target-os=android"
        CROSS_PREFIX="aarch64-linux-android-"
        LAME_LIB_PATH="$LAME_PREFIX/$ABI"
    else
        export CC="$TOOLCHAIN/bin/armv7a-linux-androideabi${API_LEVEL}-clang"
        export CXX="$TOOLCHAIN/bin/armv7a-linux-androideabi${API_LEVEL}-clang++"
        export AR="$TOOLCHAIN/bin/llvm-ar"
        export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
        export STRIP="$TOOLCHAIN/bin/llvm-strip"
        export LD="$TOOLCHAIN/bin/ld.lld"
        ARCH_FLAGS="--arch=arm --cpu=armv7-a --target-os=android"
        CROSS_PREFIX="arm-linux-androideabi-"
        LAME_LIB_PATH="$LAME_PREFIX/$ABI"
    fi
    
    # Build directory for this architecture
    BUILD_DIR="$BUILD_ROOT/build-$ABI"
    PREFIX="$BUILD_ROOT/install-$ABI"
    
    # Clean previous build
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    log_info "Configuring FFmpeg for $ABI..."
    
    cd "$FFMPEG_SRC"
    
    # Configure with minimal options
    ./configure \
        --prefix="$PREFIX" \
        --enable-cross-compile \
        $ARCH_FLAGS \
        --cc="$CC" \
        --cxx="$CXX" \
        --ar="$AR" \
        --ranlib="$RANLIB" \
        --strip="$STRIP" \
        --nm="$TOOLCHAIN/bin/llvm-nm" \
        \
        --sysroot="$TOOLCHAIN/sysroot" \
        --extra-cflags="-Os -fPIC -I$LAME_LIB_PATH/include" \
        --extra-ldflags="-L$LAME_LIB_PATH/lib" \
        \
        --enable-small \
        --enable-optimizations \
        --disable-everything \
        \
        `# Video decoders (to read video files)` \
        --enable-decoder=h264 \
        --enable-decoder=hevc \
        --enable-decoder=mpeg4 \
        --enable-decoder=mpeg2video \
        --enable-decoder=vp8 \
        --enable-decoder=vp9 \
        --enable-decoder=av1 \
        --enable-decoder=mjpeg \
        \
        `# Audio decoders (to read audio from videos)` \
        --enable-decoder=aac \
        --enable-decoder=mp3 \
        --enable-decoder=mp3float \
        --enable-decoder=vorbis \
        --enable-decoder=opus \
        --enable-decoder=flac \
        --enable-decoder=pcm_s16le \
        --enable-decoder=pcm_s24le \
        \
        `# Audio encoder (write MP3)` \
        --enable-encoder=libmp3lame \
        --enable-libmp3lame \
        \
        `# Demuxers (read video file containers)` \
        --enable-demuxer=mov \
        --enable-demuxer=mp4 \
        --enable-demuxer=m4v \
        --enable-demuxer=matroska \
        --enable-demuxer=webm \
        --enable-demuxer=avi \
        --enable-demuxer=flv \
        --enable-demuxer=mpegts \
        --enable-demuxer=mpegvideo \
        --enable-demuxer=h264 \
        --enable-demuxer=hevc \
        --enable-demuxer=aac \
        --enable-demuxer=mp3 \
        \
        `# Muxer (write MP3 files)` \
        --enable-muxer=mp3 \
        \
        `# Parsers (needed for some formats)` \
        --enable-parser=h264 \
        --enable-parser=hevc \
        --enable-parser=mpeg4video \
        --enable-parser=aac \
        --enable-parser=mp3 \
        \
        `# Filters (volume normalization)` \
        --enable-filter=loudnorm \
        --enable-filter=aresample \
        --enable-filter=aformat \
        --enable-filter=dynaudnorm \
        \
        `# Protocols` \
        --enable-protocol=file \
        \
        `# Disable unused components` \
        --disable-postproc \
        --disable-programs \
        --disable-ffmpeg \
        --disable-ffplay \
        --disable-ffprobe \
        --disable-doc \
        \
        `# Enable swscale minimally (required by ffmpeg_kit wrapper)` \
        --enable-swscale \
        --disable-swscale-alpha \
        \
        `# Enable avdevice as stub (required by ffmpeg_kit wrapper)` \
        --enable-avdevice \
        --disable-indev=* \
        --disable-outdev=* \
        --disable-htmlpages \
        --disable-manpages \
        --disable-podpages \
        --disable-txtpages \
        --disable-static \
        --enable-shared \
        --disable-vulkan \
        \
        `# Disable network/streaming (not needed)` \
        --disable-network \
        \
        `# Disable debug symbols (reduce size)` \
        --disable-debug \
        --disable-stripping
    
    log_success "Configuration completed for $ABI"
    
    # Build
    log_info "Building FFmpeg (this may take 20-40 minutes)..."
    make -j$(sysctl -n hw.ncpu)
    log_success "Build completed for $ABI"
    
    # Install
    log_info "Installing to: $PREFIX"
    make install
    log_success "Installation completed for $ABI"
    
    # Show binary sizes
    log_info "Binary sizes for $ABI:"
    ls -lh "$PREFIX/lib/"lib*.so | awk '{print "  " $9 ": " $5}'
    
    # Clean build directory to save space
    make clean
    
    log_success "✓ FFmpeg built successfully for $ABI"
}

# Build for requested architectures
if [ "$BUILD_ARCH" = "arm64" ] || [ "$BUILD_ARCH" = "both" ]; then
    build_ffmpeg_for_arch "arm64" "arm64-v8a" "aarch64-linux-android"
fi

if [ "$BUILD_ARCH" = "arm" ] || [ "$BUILD_ARCH" = "both" ]; then
    build_ffmpeg_for_arch "arm" "armeabi-v7a" "armv7a-linux-androideabi"
fi

# ============================================================================
# STEP 5: COPY BINARIES TO FLUTTER PROJECT
# ============================================================================

log_section "Step 5: Copy Binaries to Flutter Project"

# Find the Flutter project (assuming script is in project/scripts/)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
JNI_LIBS_DIR="$PROJECT_ROOT/android/app/src/main/jniLibs"

log_info "Flutter project: $PROJECT_ROOT"
log_info "Target directory: $JNI_LIBS_DIR"

# Create jniLibs directory
mkdir -p "$JNI_LIBS_DIR"

# Copy arm64-v8a libraries
if [ -d "$BUILD_ROOT/install-arm64-v8a" ]; then
    log_info "Copying arm64-v8a libraries..."
    mkdir -p "$JNI_LIBS_DIR/arm64-v8a"
    cp "$BUILD_ROOT/install-arm64-v8a/lib/"lib*.so "$JNI_LIBS_DIR/arm64-v8a/"
    
    # LAME is statically linked into FFmpeg, no separate .so needed
    
    log_success "arm64-v8a libraries copied"
fi

# Copy armeabi-v7a libraries
if [ -d "$BUILD_ROOT/install-armeabi-v7a" ]; then
    log_info "Copying armeabi-v7a libraries..."
    mkdir -p "$JNI_LIBS_DIR/armeabi-v7a"
    cp "$BUILD_ROOT/install-armeabi-v7a/lib/"lib*.so "$JNI_LIBS_DIR/armeabi-v7a/"
    
    # LAME is statically linked into FFmpeg, no separate .so needed
    
    log_success "armeabi-v7a libraries copied"
fi

# ============================================================================
# STEP 6: EXTRACT WRAPPER LIBRARIES FROM PACKAGE
# ============================================================================

log_section "Step 6: Extract Wrapper Libraries from Package"

# Find the ffmpeg_kit package in pub cache
PACKAGE_ROOT="$HOME/.pub-cache/hosted/pub.dev/ffmpeg_kit_flutter_new-4.1.0"

if [ ! -d "$PACKAGE_ROOT" ]; then
    log_error "FFmpeg Kit package not found at: $PACKAGE_ROOT"
    log_error "Please run 'flutter pub get' in your project first."
    exit 1
fi

log_info "Package found: $PACKAGE_ROOT"

# Copy wrapper libraries for each architecture
for ABI in arm64-v8a armeabi-v7a; do
    if [ -d "$JNI_LIBS_DIR/$ABI" ]; then
        log_info "Copying wrapper libraries for $ABI..."
        
        # Copy FFmpegKit wrapper (JNI bridge)
        if [ -f "$PACKAGE_ROOT/android/libs/$ABI/libffmpegkit.so" ]; then
            cp "$PACKAGE_ROOT/android/libs/$ABI/libffmpegkit.so" \
               "$JNI_LIBS_DIR/$ABI/"
            log_success "  ✓ libffmpegkit.so"
        else
            log_error "  ✗ libffmpegkit.so NOT FOUND in package!"
            exit 1
        fi
        
        # Copy ABI detector
        if [ -f "$PACKAGE_ROOT/android/libs/$ABI/libffmpegkit_abidetect.so" ]; then
            cp "$PACKAGE_ROOT/android/libs/$ABI/libffmpegkit_abidetect.so" \
               "$JNI_LIBS_DIR/$ABI/"
            log_success "  ✓ libffmpegkit_abidetect.so"
        else
            log_error "  ✗ libffmpegkit_abidetect.so NOT FOUND in package!"
            exit 1
        fi
        
        # Copy C++ standard library from NDK
        if [ "$ABI" = "arm64-v8a" ]; then
            NDK_ARCH="aarch64-linux-android"
        else
            NDK_ARCH="arm-linux-androideabi"
        fi
        
        NDK_LIBCXX="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/$NDK_ARCH/libc++_shared.so"
        
        if [ -f "$NDK_LIBCXX" ]; then
            cp "$NDK_LIBCXX" "$JNI_LIBS_DIR/$ABI/"
            log_success "  ✓ libc++_shared.so"
        else
            log_warning "  ⚠ libc++_shared.so NOT FOUND in NDK (may be provided by system)"
        fi
        
        log_success "Wrapper libraries copied for $ABI"
        echo ""
    fi
done

# ============================================================================
# STEP 7: VERIFY ALL REQUIRED LIBRARIES
# ============================================================================

log_section "Step 7: Verify All Required Libraries"

VERIFICATION_FAILED=0

for ABI in arm64-v8a armeabi-v7a; do
    if [ -d "$JNI_LIBS_DIR/$ABI" ]; then
        log_info "Verifying $ABI libraries..."
        
        # List of REQUIRED libraries for ffmpeg_kit to work
        REQUIRED_LIBS="libavcodec.so libavformat.so libavutil.so libswresample.so libswscale.so libavfilter.so libffmpegkit.so libffmpegkit_abidetect.so"
        
        MISSING_LIBS=""
        for LIB in $REQUIRED_LIBS; do
            if [ -f "$JNI_LIBS_DIR/$ABI/$LIB" ]; then
                SIZE=$(du -h "$JNI_LIBS_DIR/$ABI/$LIB" | awk '{print $1}')
                printf "  %-30s %s\n" "✓ $LIB" "$SIZE"
            else
                printf "  %-30s %s\n" "✗ $LIB" "MISSING!"
                MISSING_LIBS="$MISSING_LIBS $LIB"
                VERIFICATION_FAILED=1
            fi
        done
        
        # Check optional libc++_shared.so
        if [ -f "$JNI_LIBS_DIR/$ABI/libc++_shared.so" ]; then
            SIZE=$(du -h "$JNI_LIBS_DIR/$ABI/libc++_shared.so" | awk '{print $1}')
            printf "  %-30s %s\n" "✓ libc++_shared.so (optional)" "$SIZE"
        else
            printf "  %-30s %s\n" "⚠ libc++_shared.so (optional)" "Not found (may be system-provided)"
        fi
        
        # Calculate total size
        TOTAL=$(du -sh "$JNI_LIBS_DIR/$ABI" | awk '{print $1}')
        echo ""
        log_info "  Total size: $TOTAL"
        echo ""
        
        if [ -n "$MISSING_LIBS" ]; then
            log_error "Missing libraries in $ABI:$MISSING_LIBS"
        else
            log_success "All required libraries present for $ABI ✓"
        fi
        echo ""
    fi
done

if [ $VERIFICATION_FAILED -eq 1 ]; then
    log_error "❌ VERIFICATION FAILED! Some required libraries are missing."
    log_error "The app will crash with 'NativeLoader failed' error."
    log_error ""
    log_error "Please check the build logs above for errors during FFmpeg compilation."
    exit 1
fi

log_success "✅ All libraries verified successfully!"
echo ""

# ============================================================================
# STEP 8: FINAL SUMMARY
# ============================================================================

log_section "✓ Build Complete!"

echo ""
log_success "Minimal FFmpeg has been built successfully!"
echo ""
log_info "📦 Installed libraries:"
echo ""

if [ -d "$JNI_LIBS_DIR/arm64-v8a" ]; then
    echo "  arm64-v8a:"
    ls -lh "$JNI_LIBS_DIR/arm64-v8a/"lib*.so | awk '{print "    " $9 ": " $5}'
    
    # Calculate total size
    TOTAL_SIZE_ARM64=$(du -sh "$JNI_LIBS_DIR/arm64-v8a" | awk '{print $1}')
    echo "    Total: $TOTAL_SIZE_ARM64"
    echo ""
fi

if [ -d "$JNI_LIBS_DIR/armeabi-v7a" ]; then
    echo "  armeabi-v7a:"
    ls -lh "$JNI_LIBS_DIR/armeabi-v7a/"lib*.so | awk '{print "    " $9 ": " $5}'
    
    # Calculate total size
    TOTAL_SIZE_ARM=$(du -sh "$JNI_LIBS_DIR/armeabi-v7a" | awk '{print $1}')
    echo "    Total: $TOTAL_SIZE_ARM"
    echo ""
fi

echo ""
log_info "📝 Next Steps:"
echo ""
echo "  1. Test the build:"
echo "     cd $PROJECT_ROOT"
echo "     flutter clean"
echo "     flutter pub get"
echo "     export JAVA_HOME=/Applications/Android\\ Studio.app/Contents/jbr/Contents/Home"
echo "     flutter run -d a2a42a1c"
echo ""
echo "  2. Test all video formats (see TESTING_MINIMAL_FFMPEG.md)"
echo ""
echo "  3. Build production bundle:"
echo "     flutter build appbundle --release --dart-define=PRODUCTION=true"
echo ""
echo "  4. Check final size:"
echo "     ls -lh build/app/outputs/bundle/release/app-release.aab"
echo ""
log_success "Expected app size: 25-30 MB (.aab) → 12-15 MB (user download)"
echo ""
