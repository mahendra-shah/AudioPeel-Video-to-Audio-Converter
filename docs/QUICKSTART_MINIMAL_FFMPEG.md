# Quick Start: Reduce AudioPeel from 130MB to 12-15MB

**Time required:** 2-4 hours for initial build, then 30 minutes for testing

---

## Prerequisites Check

```bash
# 1. Check Android NDK is installed
ls ~/Library/Android/sdk/ndk/
# Should show: 27.0.12077973 (or similar version)

# 2. Check build tools
which autoconf automake libtool pkg-config wget
# All should return paths

# If any missing:
brew install autoconf automake libtool pkg-config wget nasm yasm
```

---

## Step-by-Step Build Process

### 1. Make Scripts Executable (30 seconds)

```bash
cd /Users/mahendra/work-dir/call-assitant/scripts
chmod +x build-ffmpeg-minimal.sh
chmod +x build-lame.sh
```

### 2. Set Environment Variables (30 seconds)

```bash
# Set NDK path (update if your version is different)
export ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/27.0.12077973

# Verify it exists
ls $ANDROID_NDK_HOME
```

### 3. Run the Build Script (2-4 hours)

```bash
# Build for both 32-bit and 64-bit (recommended)
./build-ffmpeg-minimal.sh both

# OR build only 64-bit (faster, covers 95% of devices)
# ./build-ffmpeg-minimal.sh arm64
```

**What happens:**
- Downloads FFmpeg source (~5 minutes)
- Downloads and builds LAME library (~10 minutes)
- Builds minimal FFmpeg for arm64-v8a (~40-90 minutes)
- Builds minimal FFmpeg for armeabi-v7a (~40-90 minutes)
- Copies binaries to your Flutter project (~1 minute)

**You can grab coffee/lunch during the build** ☕

### 4. Test the Build (15 minutes)

```bash
cd /Users/mahendra/work-dir/call-assitant

# Clean previous builds
flutter clean
flutter pub get

# Run on your device
export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home
flutter run -d a2a42a1c
```

**Quick Test:**
1. Open app
2. Pick a video (any MP4 file)
3. Convert to MP3
4. Verify it works

### 5. Build Production Bundle (10 minutes)

```bash
cd /Users/mahendra/work-dir/call-assitant

# Build release bundle
flutter build appbundle --release --dart-define=PRODUCTION=true

# Check size
ls -lh build/app/outputs/bundle/release/app-release.aab
```

**Expected result:**
```
app-release.aab: 25-30 MB  ← Down from 136 MB! 🎉
```

### 6. Verify User Download Size

```bash
# Build split APKs to see per-device size
flutter build apk --release --split-per-abi --dart-define=PRODUCTION=true

# Check sizes
ls -lh build/app/outputs/flutter-apk/
```

**Expected result:**
```
app-arm64-v8a-release.apk:   13-15 MB  ← This is what users download!
app-armeabi-v7a-release.apk: 12-14 MB
```

---

## Troubleshooting

### Build fails: "NDK not found"

```bash
# Set NDK path explicitly
export ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/27.0.12077973
```

### Build fails: "Command not found: autoconf"

```bash
# Install build tools
brew install autoconf automake libtool pkg-config wget nasm yasm
```

### Build fails: "Cannot find LAME library"

```bash
# Build LAME first
cd /Users/mahendra/work-dir/call-assitant/scripts
./build-lame.sh both
```

### App crashes after integration

```bash
# Check libraries were copied
ls android/app/src/main/jniLibs/arm64-v8a/

# Should show:
# libavcodec.so
# libavformat.so
# libavutil.so
# libswresample.so
# libmp3lame.so
```

### Specific video format doesn't work

Check if decoder is enabled in `build-ffmpeg-minimal.sh`:
```bash
grep "enable-decoder" scripts/build-ffmpeg-minimal.sh
```

Add missing decoder if needed (e.g., `--enable-decoder=wmv3`)

---

## Skip the Build? (For Testing Only)

**Option A:** Use pre-built minimal FFmpeg
- Some developers share pre-compiled binaries
- NOT recommended for production (unknown source)
- Can use for testing approach before building yourself

**Option B:** Quick test with audio-only package
```yaml
# In pubspec.yaml, temporarily try:
dependencies:
  ffmpeg_kit_flutter_audio: ^6.1.0  # ~40-50 MB
```

This gives ~50 MB app (not 15 MB, but faster to test concept).

---

## Timeline Summary

| Task | Time | Can Work During? |
|------|------|------------------|
| Prerequisites setup | 10 min | No |
| Build LAME | 10 min | Yes (compiling) |
| Build FFmpeg (arm64) | 40-90 min | Yes (compiling) |
| Build FFmpeg (arm32) | 40-90 min | Yes (compiling) |
| Integration test | 15 min | No |
| Production build | 10 min | Yes (building) |
| **Total active work** | **~45 min** | |
| **Total elapsed time** | **2-4 hours** | |

---

## What's Included in Minimal Build

### ✅ What You KEEP
- All video decoders (H.264, H.265, VP8, VP9, AV1, MPEG-4, etc.)
- All audio decoders (AAC, MP3, Vorbis, Opus, FLAC)
- MP3 encoder (LAME)
- All container formats (MP4, MKV, AVI, MOV, FLV, WebM, etc.)
- Volume normalization (loudnorm filter)
- All existing app features

### ❌ What Gets REMOVED
- Video encoders (you never encode video)
- Image codecs (PNG, JPEG - not needed)
- Subtitle codecs (not needed)
- Network streaming (RTMP, HLS - app works offline)
- Advanced filters (blur, rotate, etc. - only need audio filters)
- Debug symbols and documentation

---

## Size Comparison

### Before (Current)
```
FFmpeg libraries: 110 MB
Flutter + App:     20 MB
Total .aab:       130 MB
User download:     80-90 MB ❌
```

### After (Minimal FFmpeg)
```
FFmpeg libraries:   7 MB  (93% reduction)
Flutter + App:     20 MB  (same)
Total .aab:        27 MB  (79% reduction)
User download:  12-15 MB  (83% reduction) ✅
```

---

## Success Metrics

After implementation, you should see:

✅ **Play Store shows:** "13 MB" (not 80-90 MB)
✅ **Faster downloads:** 6x faster download time
✅ **Less storage:** 6x less device storage used
✅ **Better ratings:** Users mention "lightweight" in reviews
✅ **All features work:** 100% functionality preserved

---

## Need Help?

1. Check build logs: `~/work-dir/ffmpeg-minimal-build/*.log`
2. Review documentation: `/docs/MINIMAL_FFMPEG_IMPLEMENTATION.md`
3. Check testing guide: `/docs/TESTING_MINIMAL_FFMPEG.md`
4. Compare with reference: Your build should match sizes in docs

---

## Ready to Start?

```bash
cd /Users/mahendra/work-dir/call-assitant/scripts
chmod +x *.sh
./build-ffmpeg-minimal.sh both
```

Then grab a coffee ☕ - the script will run for 2-4 hours and do everything automatically!
