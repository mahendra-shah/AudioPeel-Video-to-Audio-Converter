# Minimal FFmpeg Implementation Guide

**Goal:** Reduce app size from 130MB → 12-15MB while keeping all features

**Timeline:** 30-40 hours over 2-3 weeks

**Status:** Ready to implement

---

## Overview

This guide will walk you through building a minimal FFmpeg library for Android that includes only the codecs and features AudioPeel actually uses, resulting in an 87% size reduction with zero functionality loss.

## What We're Doing

### Current State
- **Package:** `ffmpeg_kit_flutter_new: ^4.1.0` (full FFmpeg build)
- **Binary size:** ~110 MB (includes ALL video codecs, image processing, streaming)
- **App size:** 130 MB (.aab) → 80-90 MB (user download)

### Target State
- **Package:** Custom minimal FFmpeg build
- **Binary size:** ~7-8 MB (only needed codecs)
- **App size:** 25-30 MB (.aab) → 12-15 MB (user download)

### What's Kept
✅ All video formats (MP4, MKV, AVI, MOV, FLV, WebM, 3GP, etc.)
✅ MP3 output (all quality levels: 128k, 192k, 320k)
✅ Volume normalization (loudnorm filter)
✅ Background conversion
✅ Progress notifications
✅ All existing features

### What's Removed
❌ Video encoding (we only read videos, never write them)
❌ Image codecs (PNG, JPEG - not needed)
❌ Advanced streaming protocols (RTMP, HLS - not needed)
❌ Subtitle processing (not needed)
❌ 100+ unused filters

---

## Prerequisites

### System Requirements
- **OS:** macOS (you have this ✅)
- **Storage:** ~10 GB free space for build
- **Time:** 2-4 hours for initial build

### Required Software

1. **Android NDK** (Native Development Kit)
   ```bash
   # Check if already installed
   ls ~/Library/Android/sdk/ndk
   
   # If not installed, use Android Studio SDK Manager:
   # Tools → SDK Manager → SDK Tools → NDK (Side by side)
   # Install version 27.0.12077973 or latest
   ```

2. **Build Tools** (via Homebrew)
   ```bash
   # Install Homebrew if you don't have it
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   
   # Install required tools
   brew install autoconf automake libtool pkg-config wget nasm yasm
   ```

3. **LAME Library** (MP3 encoder)
   ```bash
   # We'll download and compile this as part of FFmpeg build
   # No separate installation needed
   ```

---

## Implementation Phases

### Phase 1: Environment Setup (2-4 hours)
1. Install required build tools
2. Clone FFmpeg source code
3. Download LAME MP3 library
4. Set up Android NDK paths
5. Verify build environment

### Phase 2: Build FFmpeg (4-8 hours)
1. Build LAME library for Android (arm64-v8a)
2. Build LAME library for Android (armeabi-v7a)
3. Build minimal FFmpeg for arm64-v8a
4. Build minimal FFmpeg for armeabi-v7a
5. Verify binary sizes

### Phase 3: Integration (4-8 hours)
1. Replace FFmpeg binaries in your app
2. Update build configuration
3. Test all video formats
4. Test all quality settings
5. Test volume normalization

### Phase 4: Testing & Deployment (4-6 hours)
1. Test on multiple devices
2. Build production bundle
3. Verify final app size
4. Deploy to Play Store
5. Monitor for issues

---

## Quick Start

### Step 1: Check Prerequisites
```bash
# Verify Android SDK location
echo $ANDROID_HOME
# Expected: /Users/mahendra/Library/Android/sdk

# Verify NDK installation
ls ~/Library/Android/sdk/ndk/
# Should show version folders like: 27.0.12077973

# Verify build tools
which autoconf automake libtool pkg-config
# Should show paths for all tools
```

### Step 2: Create Build Directory
```bash
cd ~/work-dir
mkdir ffmpeg-minimal-build
cd ffmpeg-minimal-build
```

### Step 3: Follow Detailed Instructions
Continue to the detailed implementation scripts in:
- `scripts/build-ffmpeg-minimal.sh` - Main build script
- `scripts/build-lame.sh` - LAME MP3 encoder build
- `scripts/integrate-binaries.sh` - Integration script

---

## Expected Results

### Binary Sizes
| Component | Before | After | Reduction |
|-----------|--------|-------|-----------|
| libavcodec.so (arm64) | ~35 MB | ~3-4 MB | 89% |
| libavformat.so (arm64) | ~5 MB | ~1-2 MB | 70% |
| libavutil.so (arm64) | ~3 MB | ~1 MB | 67% |
| **Total per ABI** | **~50 MB** | **~7 MB** | **86%** |

### App Sizes
| Build Type | Before | After | Reduction |
|------------|--------|-------|-----------|
| .aab (upload) | 130-136 MB | 25-30 MB | 79% |
| arm64-v8a APK | 80-90 MB | 13-15 MB | 83% |
| armeabi-v7a APK | 70-80 MB | 12-14 MB | 83% |

### User Experience
- **Download time:** 80-90 MB → 13-15 MB (83% faster)
- **Storage used:** 80-90 MB → 13-15 MB (83% less)
- **Install time:** Proportionally faster
- **Functionality:** 100% identical

---

## Troubleshooting

### Build Fails with "Command not found"
**Problem:** Missing build tools
**Solution:**
```bash
brew install autoconf automake libtool pkg-config
```

### Build Fails with "NDK not found"
**Problem:** NDK path not set correctly
**Solution:**
```bash
export ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/27.0.12077973
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH
```

### FFmpeg configure fails
**Problem:** LAME library not found
**Solution:** Build LAME first using `build-lame.sh` script

### App crashes after integration
**Problem:** Missing shared libraries
**Solution:** Verify all .so files are in `android/app/src/main/jniLibs/`

### Format doesn't work after build
**Problem:** Demuxer not enabled
**Solution:** Check configure flags include `--enable-demuxer=<format>`

---

## Rollback Plan

If something goes wrong, you can revert to the full FFmpeg build:

```bash
# Remove custom binaries
rm -rf android/app/src/main/jniLibs/

# Clean and rebuild with original package
flutter clean
flutter pub get
flutter build appbundle --release --dart-define=PRODUCTION=true
```

Your app will work exactly as before (just be 130 MB again).

---

## Next Steps

1. Review this guide completely
2. Set up build environment (Phase 1)
3. Run build scripts (Phase 2)
4. Integrate binaries (Phase 3)
5. Test thoroughly (Phase 4)

**Ready to start?** Begin with Phase 1 environment setup.

---

## Support & Resources

### Documentation
- FFmpeg Configuration Guide: https://ffmpeg.org/ffmpeg-all.html
- Android NDK Guide: https://developer.android.com/ndk/guides
- LAME Documentation: https://lame.sourceforge.io/

### Your Project Files
- Build scripts: `/Users/mahendra/work-dir/call-assitant/scripts/`
- Integration docs: `/Users/mahendra/work-dir/call-assitant/docs/`
- Test checklist: `/Users/mahendra/work-dir/call-assitant/docs/TESTING_MINIMAL_FFMPEG.md`

### Estimated Timeline
- **Week 1 (16h):** Setup environment + Build FFmpeg
- **Week 2 (12h):** Integration + Initial testing
- **Week 3 (8h):** Thorough testing + Deployment

**Total:** 36 hours spread over 2-3 weeks
