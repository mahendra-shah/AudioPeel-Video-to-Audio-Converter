# Minimal FFmpeg Testing Checklist

After building and integrating minimal FFmpeg binaries, use this checklist to verify everything works correctly.

## Pre-Test Setup

```bash
# Clean build
cd /Users/mahendra/work-dir/call-assitant
flutter clean
flutter pub get

# Run on device
export JAVA_HOME=/Applications/Android\ Studio.app/Contents/jbr/Contents/Home
flutter run -d a2a42a1c
```

---

## Test Matrix

### 1. Video Format Support

Test each video format your app claims to support. Convert a sample of each and verify:
- File is picked successfully
- Conversion completes without errors
- Output MP3 plays correctly
- File appears in history

| Format | Container | Common Codecs | Status | Notes |
|--------|-----------|---------------|--------|-------|
| **MP4** | MPEG-4 | H.264, AAC | ⬜ | Most common format (80% of videos) |
| **MOV** | QuickTime | H.264, AAC | ⬜ | iPhone videos |
| **MKV** | Matroska | H.264/H.265, various | ⬜ | High-quality downloads |
| **AVI** | AVI | MPEG-4, MP3 | ⬜ | Legacy Windows format |
| **FLV** | Flash Video | H.264, AAC | ⬜ | YouTube downloads (older) |
| **WebM** | WebM | VP8/VP9, Opus/Vorbis | ⬜ | Web videos |
| **3GP** | 3GPP | H.263/H.264, AMR | ⬜ | Old mobile videos |
| **TS** | MPEG-TS | H.264, AAC | ⬜ | TV recordings |
| **M4V** | iTunes | H.264, AAC | ⬜ | iTunes videos |

**Test samples:** You can download sample videos from:
- https://sample-videos.com/
- https://test-videos.co.uk/
- Or use your own video files

**How to test:**
1. Open AudioPeel
2. Tap "Choose Video"
3. Select test video
4. Choose quality (192 kbps recommended for testing)
5. Start conversion
6. Wait for completion
7. Play resulting MP3 in a music player
8. Verify audio is correct (no corruption, proper length)

---

### 2. Audio Quality Settings

Test all three quality presets:

| Quality | Bitrate | Status | Test File | Output Size | Notes |
|---------|---------|--------|-----------|-------------|-------|
| **Standard** | 128 kbps | ⬜ | test-video.mp4 | ~1MB/min | Smallest file |
| **High** | 192 kbps | ⬜ | test-video.mp4 | ~1.4MB/min | Balanced |
| **Very High** | 320 kbps | ⬜ | test-video.mp4 | ~2.4MB/min | Highest quality |

**Verification:**
- Check output file size matches expected (roughly)
- Play each file - higher bitrates should sound noticeably better
- Verify file metadata (ID3 tags) if present

---

### 3. Volume Normalization

Test loudnorm filter functionality:

| Test Case | Input | Normalization | Status | Observation |
|-----------|-------|---------------|--------|-------------|
| **Quiet video** | Low volume file | ✅ ON | ⬜ | Output should be louder |
| **Quiet video** | Low volume file | ❌ OFF | ⬜ | Output matches input |
| **Loud video** | High volume file | ✅ ON | ⬜ | Output should be normalized |
| **Normal video** | Normal volume | ✅ ON | ⬜ | Output similar to input |

**How to test:**
1. Settings → Toggle "Normalize Volume"
2. Convert same video with ON and OFF
3. Compare output volumes in music player

---

### 4. Edge Cases & Error Handling

| Test Case | Expected Behavior | Status | Notes |
|-----------|-------------------|--------|-------|
| **Very large file** (>2GB) | Converts successfully or shows meaningful error | ⬜ | |
| **Very short file** (<1 sec) | Converts successfully | ⬜ | |
| **Corrupted file** | Shows error message | ⬜ | |
| **Audio-only file** (MP3) | Converts (audio copy) or shows message | ⬜ | |
| **No audio track** | Shows "No audio track found" error | ⬜ | |
| **Uncommon codec** (AV1, VP6) | Converts if decoder enabled, error if not | ⬜ | |

---

### 5. App Functionality

Test core app features:

| Feature | Status | Notes |
|---------|--------|-------|
| **File picker** opens | ⬜ | |
| **Conversion progress** shows | ⬜ | |
| **Background conversion** works | ⬜ | Lock screen or switch apps during conversion |
| **Notification** appears | ⬜ | Check notification shows progress |
| **Completion notification** | ⬜ | Check notification on completion |
| **Play from notification** | ⬜ | Tap play button in notification |
| **Recent conversions** display | ⬜ | Check home screen |
| **History** populates | ⬜ | Check history screen |
| **Share** functionality | ⬜ | Share output file |
| **Set as ringtone** | ⬜ | Set output as ringtone |
| **Delete** functionality | ⬜ | Delete from 3-dot menu |

---

### 6. Binary Size Verification

Check installed libraries are minimal:

```bash
# Check jniLibs directory
ls -lh android/app/src/main/jniLibs/arm64-v8a/
ls -lh android/app/src/main/jniLibs/armeabi-v7a/

# Expected sizes (arm64-v8a):
# libavcodec.so:    ~3-4 MB ✓
# libavformat.so:   ~1-2 MB ✓
# libavutil.so:     ~1 MB ✓
# libswresample.so: ~0.3-0.5 MB ✓
# libmp3lame.so:    ~0.3-0.5 MB ✓
# TOTAL:            ~6-8 MB ✓

# If any library is >5 MB, rebuild may be needed
```

---

### 7. Production Build Test

Build production bundle and verify size:

```bash
flutter clean
flutter pub get
flutter build appbundle --release --dart-define=PRODUCTION=true

# Check bundle size
ls -lh build/app/outputs/bundle/release/app-release.aab

# Expected: 25-30 MB (down from 130-136 MB)

# Build APKs to see per-architecture sizes
flutter build apk --release --split-per-abi --dart-define=PRODUCTION=true

ls -lh build/app/outputs/flutter-apk/

# Expected:
# app-arm64-v8a-release.apk:   ~13-15 MB
# app-armeabi-v7a-release.apk: ~12-14 MB
```

---

### 8. Production APK Installation Test

Test actual production build on device:

```bash
# Install production APK
flutter install --release

# Test in production mode:
# - Real AdMob ads should show (not "Test Ad")
# - All conversion features work
# - No crashes or performance issues
```

| Test | Status | Notes |
|------|--------|-------|
| **App installs** | ⬜ | |
| **Real ads show** | ⬜ | Banner + Interstitial |
| **All formats work** | ⬜ | Test 3-4 common formats |
| **Performance OK** | ⬜ | No lag or slowness |
| **No crashes** | ⬜ | Test for 10-15 minutes |

---

### 9. Regression Testing

Verify existing features still work:

| Feature | Status | Notes |
|---------|--------|-------|
| **Dark mode** | ⬜ | Toggle theme in settings |
| **Quality selection** | ⬜ | Change default quality |
| **Output path** | ⬜ | Change output folder |
| **Auto-delete original** | ⬜ | Toggle setting |
| **Privacy policy link** | ⬜ | Opens Google Docs |
| **About dialog** | ⬜ | Shows app info |

---

### 10. Performance Benchmarks

Compare conversion speed before/after:

| Video | Size | Format | Before | After | Difference |
|-------|------|--------|--------|-------|------------|
| Sample 1 | 50 MB | MP4 | ___s | ___s | ___ |
| Sample 2 | 100 MB | MKV | ___s | ___s | ___ |
| Sample 3 | 200 MB | MOV | ___s | ___s | ___ |

**Note:** Performance should be similar or slightly better (less library overhead).

---

## Known Issues / Limitations

Document any issues found:

| Issue | Severity | Workaround | Fix Plan |
|-------|----------|------------|----------|
| | | | |

---

## Success Criteria

All tests must pass before deploying to production:

- ✅ All common formats convert successfully
- ✅ All quality settings work
- ✅ Volume normalization works
- ✅ No crashes or errors in normal usage
- ✅ Bundle size is 25-30 MB (.aab)
- ✅ User download size is 12-15 MB (split APK)
- ✅ Production build works with real ads
- ✅ Performance is unchanged or better

---

## Rollback Procedure

If tests fail and issues can't be resolved quickly:

```bash
# Remove custom binaries
rm -rf android/app/src/main/jniLibs/

# Rebuild with original FFmpeg package
flutter clean
flutter pub get
flutter build appbundle --release --dart-define=PRODUCTION=true

# This reverts to 130 MB build but ensures app works
```

---

## Timeline

- **Day 1-2:** Build FFmpeg binaries
- **Day 3:** Integration & initial testing
- **Day 4-5:** Complete test matrix
- **Day 6:** Production build & deployment prep
- **Day 7:** Final checks & Play Store upload

---

## Report Template

After testing, document results:

```
# Minimal FFmpeg Testing Report

Date: ___________
Tester: ___________

## Summary
- Total tests: ___
- Passed: ___
- Failed: ___
- Skipped: ___

## Pass Rate: ____%

## Critical Issues
(List any blockers)

## Minor Issues
(List non-blocking issues)

## Performance
- Conversion speed: Unchanged / Faster / Slower
- App responsiveness: Good / Acceptable / Poor

## Size Metrics
- Bundle size: ___ MB
- User download (arm64): ___ MB
- User download (arm32): ___ MB
- Reduction: ___% from original

## Recommendation
✅ Ready for production / ⚠️ Needs fixes / ❌ Not ready

## Notes
(Additional observations)
```

---

## Resources

- **Sample videos:** https://sample-videos.com/
- **FFmpeg formats:** https://ffmpeg.org/ffmpeg-formats.html
- **Codecs reference:** https://ffmpeg.org/ffmpeg-codecs.html
- **Issue tracker:** /Users/mahendra/work-dir/call-assitant/docs/
