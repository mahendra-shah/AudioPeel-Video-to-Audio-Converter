# Testing Guide: Audio Format Conversion

## Quick Test Procedure

### 1. Test MP3 (Most Important - Should Always Work)
1. Select a video file
2. Choose **MP3** format
3. Choose any quality (128k, 192k, or 320k)
4. Tap "EXTRACT AUDIO"
5. ✅ Should complete successfully
6. Check the file plays correctly

### 2. Test M4A/AAC (iOS Compatible Format)
1. Select the same video
2. Choose **M4A** format  
3. Tap "EXTRACT AUDIO"
4. ✅ Should complete successfully
5. File should have .m4a extension

### 3. Test AAC (Raw AAC Stream)
1. Choose **AAC** format
2. Tap "EXTRACT AUDIO"
3. ✅ Should complete successfully
4. File should have .aac extension

### 4. Test WAV (Uncompressed)
1. Choose **WAV** format
2. Tap "EXTRACT AUDIO"
3. ✅ Should complete successfully
4. File size will be much larger (uncompressed)

### 5. Test FLAC (Lossless Compression)
1. Choose **FLAC** format
2. Tap "EXTRACT AUDIO"
3. ✅ Should complete successfully
4. File size larger than MP3 but smaller than WAV

### 6. Test OPUS (May Fail on Some Devices)
1. Choose **OPUS** format
2. Tap "EXTRACT AUDIO"
3. ⚠️ May show error: "The selected audio format is not supported"
4. If it fails, this is expected - OPUS requires GPL codecs

### 7. Test OGG (May Fail on Some Devices)
1. Choose **OGG** format
2. Tap "EXTRACT AUDIO"
3. ⚠️ May show error about unsupported format
4. If it fails, this is expected - Vorbis codec may not be available

### 8. Test WMA (Will Use Fallback)
1. Choose **WMA** format
2. Tap "EXTRACT AUDIO"
3. ⚠️ Will actually create M4A file (AAC fallback)
4. Check console for warning message

## Expected Results

### Should Always Work ✅
- MP3
- M4A  
- AAC
- WAV
- FLAC

### May Not Work ⚠️
- OPUS (requires libopus)
- OGG (requires libvorbis)
- WMA (may not be available, falls back to AAC)

## Error Messages to Watch For

### "The selected audio format is not supported by your device"
- Means the FFmpeg codec is not available in the build
- Try MP3 or M4A instead

### "This audio format is not supported. Please try MP3."
- Generic codec error
- The format's encoder is missing from FFmpeg

### "Encoder not found" (in console logs)
- Specific codec like `libopus` or `libvorbis` is missing
- Expected for OPUS/OGG on standard builds

## What to Report

For each format that **fails**, please note:

1. **Format name** (e.g., "OPUS")
2. **Error message shown** to the user
3. **Console output** (check Flutter DevTools or logcat)
4. **Video file** you're testing with (format, size)

## File Verification

After successful conversion, verify:

1. ✅ **File exists** in the expected location
2. ✅ **Extension is correct** (.mp3, .m4a, .aac, etc.)
3. ✅ **File size is reasonable** (not 0 bytes)
4. ✅ **File plays** in a media player
5. ✅ **Audio quality** is acceptable

## Quick Format Recommendations

### For Maximum Compatibility
Use **MP3** - works everywhere, widely supported

### For Best Quality
Use **FLAC** - lossless compression, perfect quality

### For iOS/Apple Devices
Use **M4A** - AAC in MP4 container, native iOS format

### For Small File Size
Use **MP3** at 128k or **OPUS** at 64k (if available)

### For Voice/Podcasts
Use **OPUS** (if available) or **MP3** at 128k

### For Archival/Studio Use
Use **FLAC** or **WAV** - lossless, no quality loss

## Troubleshooting

### All Formats Fail
- Check storage permissions
- Ensure enough free space
- Try with different video file
- Check video file isn't corrupted

### Only MP3 Works
- This is normal - means you have a minimal FFmpeg build
- Stick with MP3, M4A, AAC, WAV, FLAC

### Conversion Hangs
- Wait for timeout (configured in app)
- Check video file size (very large files take time)
- Try smaller video first

### Poor Audio Quality
- Increase bitrate (use 320k instead of 128k)
- Use lossless format (FLAC or WAV)
- Check source video audio quality

## Developer Notes

If you need full codec support:

1. Change pubspec.yaml:
```yaml
dependencies:
  ffmpeg_kit_flutter_full_gpl: ^4.1.0
```

2. Run:
```bash
flutter clean
flutter pub get
flutter run
```

3. Note: App size will increase by 30-50MB

## Console Commands to Check Codecs

To see which codecs are available in your FFmpeg build:

```bash
# In Flutter app (add temporary code):
await FFmpegKit.execute('-codecs');
await FFmpegKit.execute('-encoders');
```

Look for:
- `libmp3lame` - MP3 support
- `aac` - AAC support
- `libopus` - OPUS support
- `libvorbis` - OGG/Vorbis support
- `flac` - FLAC support
- `pcm_s16le` - WAV support
- `wmav2` - WMA support
