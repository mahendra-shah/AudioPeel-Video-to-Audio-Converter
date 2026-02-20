# Settings Screen Redesign - Complete Implementation

## 🎯 Overview

Complete redesign of the Settings screen with all new extraction engine features, following the reference design. This implementation adds support for multiple audio formats, sample rates, channels, and several automation/experience features.

## ✅ What's Been Implemented

### **1. New Models**

#### **AudioFormat** (`lib/models/audio_format.dart`)
Supports 8 audio output formats:
- MP3 (MPEG Audio)
- AAC (Advanced Audio Coding)
- OPUS (Opus Interactive Audio Codec)
- FLAC (Free Lossless Audio Codec)
- WAV (Waveform Audio)
- OGG (Ogg Vorbis)
- M4A (MPEG-4 Audio)
- WMA (Windows Media Audio)

Each format includes:
- Display name
- File extension
- MIME type for sharing

#### **SampleRate** (`lib/models/sample_rate.dart`)
Supports 5 sample rates:
- 32 kHz (32,000 Hz)
- 44.1 kHz (44,100 Hz) - CD quality, default
- 48 kHz (48,000 Hz) - DVD quality
- 96 kHz (96,000 Hz) - Hi-Res audio
- 192 kHz (192,000 Hz) - Studio quality

#### **AudioChannel** (`lib/models/audio_channel.dart`)
Supports 2 channel configurations:
- Mono (1 channel)
- Stereo (2 channels) - default

### **2. Extended SettingsProvider**

#### **New Settings Added:**
- `defaultFormat` - Audio output format (MP3, AAC, OPUS, etc.)
- `defaultSampleRate` - Sample rate (32kHz - 192kHz)
- `defaultChannel` - Channel configuration (Mono/Stereo)
- `smartId3Tagging` - Auto-fill metadata from video
- `hapticFeedback` - Vibration on interactions
- `cloudSyncEnabled` - Google Drive backup (UI only, functionality TBD)

#### **New Methods:**
- `setDefaultFormat(AudioFormat)` - Set audio format
- `setDefaultSampleRate(SampleRate)` - Set sample rate
- `setDefaultChannel(AudioChannel)` - Set channel config
- `toggleSmartId3Tagging()` - Toggle ID3 tagging
- `toggleHapticFeedback()` - Toggle haptic feedback
- `toggleCloudSync()` - Toggle cloud sync (UI only)
- `performHaptic()` - Trigger haptic feedback

All settings are persisted via SharedPreferences.

### **3. CacheService**

New service for cache management (`lib/services/cache_service.dart`):
- `getCacheSize()` - Calculate total cache size
- `clearCache()` - Delete all cached files
- Uses path_provider to access temp directory
- Recursive directory size calculation
- Error handling and logging

### **4. Settings Screen**

Complete redesign following reference UI (`lib/screens/settings_screen.dart`):

#### **Section 1: EXTRACTION ENGINE**
- **Default Format** - Select output format (MP3, AAC, OPUS, etc.)
- **Bitrate** - Audio quality (128/192/320 kbps)
- **Sample Rate** - Audio sample rate (32-192 kHz)
- **Channel** - Mono or Stereo output

#### **Section 2: AUTOMATION**
- **Smart ID3 Tagging** - Auto-fill metadata from video filename
- **Auto-delete Source** - Delete original video after conversion
- **Normalize Volume** - Balance audio levels during conversion

#### **Section 3: STORAGE**
- **Output Path** - Choose where converted files are saved
- **Cloud Sync** - Google Drive backup (UI placeholder)

#### **Section 4: EXPERIENCE**
- **Theme** - System/Light/OLED Dark
- **Haptic Feedback** - Vibration on button taps

#### **Section 5: SUPPORT**
- **Clear Cache** - Shows cache size, allows clearing
- **Restore Purchases** - Restore IAP (Remove Ads)
- **About Vibe** - App info and version

#### **UI Features:**
- Color-coded icons for each setting (Purple, Blue, Green, Orange, etc.)
- Modal bottom sheet pickers for all selection options
- Haptic feedback on all interactions (when enabled)
- Toggle switches with adaptive styling
- Navigation tiles with chevron indicators
- Clean card-based layout
- Proper section headers
- Remove Ads CTA banner (when not purchased)

### **5. App Strings**

Extended `app_strings.dart` with new labels:
- Extraction engine section labels
- Automation feature labels
- Experience feature labels
- Support section labels
- Picker dialog titles
- All subtitle/description texts

## 📦 Files Created

1. `lib/models/audio_format.dart` - Audio format enum
2. `lib/models/sample_rate.dart` - Sample rate enum
3. `lib/models/audio_channel.dart` - Channel config enum
4. `lib/services/cache_service.dart` - Cache management service
5. `lib/screens/settings_screen.dart` - Redesigned settings UI

## 📝 Files Modified

1. `lib/providers/settings_provider.dart` - Added new settings + persistence
2. `lib/constants/app_strings.dart` - Added new string constants
3. `lib/screens/settings_screen_old.dart` - Backup of old implementation

## 🧪 Testing

- ✅ All 88 existing tests pass
- ✅ `dart analyze` reports 0 issues
- ✅ Code formatted with `dart format`
- ✅ No compilation errors

## 🚀 Next Steps (To Fully Integrate)

### **Phase 1: Update FFmpegService**

The `FFmpegService` currently hardcodes MP3 output. It needs to be updated to support all formats:

```dart
// lib/services/ffmpeg_service.dart - UPDATE NEEDED

Future<ConversionResult> convertVideo({
  required String inputPath,
  required String outputPath,
  required AudioQuality quality,
  required AudioFormat format,        // NEW
  required SampleRate sampleRate,     // NEW
  required AudioChannel channel,      // NEW
  required int videoDurationMs,
  bool normalizeVolume = false,
  void Function(double progress)? onProgress,
}) async {
  // Build FFmpeg command based on format
  final String codecParams;
  switch (format) {
    case AudioFormat.mp3:
      codecParams = '-c:a libmp3lame -b:a ${quality.kbps}k';
    case AudioFormat.aac:
      codecParams = '-c:a aac -b:a ${quality.kbps}k';
    case AudioFormat.opus:
      codecParams = '-c:a libopus -b:a ${quality.kbps}k';
    case AudioFormat.flac:
      codecParams = '-c:a flac';
    case AudioFormat.wav:
      codecParams = '-c:a pcm_s16le';
    case AudioFormat.ogg:
      codecParams = '-c:a libvorbis -b:a ${quality.kbps}k';
    case AudioFormat.m4a:
      codecParams = '-c:a aac -b:a ${quality.kbps}k';
    case AudioFormat.wma:
      codecParams = '-c:a wmav2 -b:a ${quality.kbps}k';
  }

  final audioFilter = normalizeVolume ? '-af loudnorm ' : '';
  final command =
      '-i "$inputPath" -vn '
      '$audioFilter'
      '-ar ${sampleRate.hz} '
      '-ac ${channel.count} '
      '$codecParams '
      '"$outputPath"';
      
  // ...rest of conversion logic
}
```

### **Phase 2: Update ConversionProvider**

Update `ConversionProvider` to use settings:

```dart
// lib/providers/conversion_provider.dart - UPDATE NEEDED

Future<void> startConversion(SettingsProvider settings) async {
  // Use settings for format, sample rate, channel
  final result = await _ffmpegService.convertVideo(
    inputPath: _selectedVideo!.path,
    outputPath: outputPath,
    quality: _quality,
    format: settings.defaultFormat,        // NEW
    sampleRate: settings.defaultSampleRate,  // NEW
    channel: settings.defaultChannel,        // NEW
    videoDurationMs: _videoDurationMs,
    normalizeVolume: settings.normalizeVolume,
    onProgress: (progress) {
      _task = _task!.copyWith(progress: progress);
      notifyListeners();
    },
  );
  
  // ...rest of conversion logic
}
```

### **Phase 3: Update File Naming**

Update output file naming to use correct extension:

```dart
// lib/providers/conversion_provider.dart
// Update selectVideo() method:

Future<bool> selectVideo() async {
  // ...existing code...
  
  // Get format from settings
  final format = _settingsProvider.defaultFormat;
  _outputName = FileUtils.defaultOutputName(
    path, 
    extension: format.extension  // Use dynamic extension
  );
  
  // ...rest of code
}
```

### **Phase 4: Smart ID3 Tagging**

Implement ID3 tag extraction if enabled:

```dart
// Create lib/services/id3_service.dart

class Id3Service {
  /// Extracts metadata from video filename and applies to audio file
  Future<void> tagAudioFile(
    String videoPath, 
    String audioPath,
    {bool enabled = true}
  ) async {
    if (!enabled) return;
    
    // Extract title from filename
    final title = extractTitle(videoPath);
    
    // Use id3 package or ffmpeg metadata to tag file
    // ...implementation
  }
}
```

### **Phase 5: Cloud Sync (Future)**

The cloud sync toggle is currently a UI placeholder. To implement:

1. Add Google Drive API integration
2. Implement automatic upload after conversion
3. Add sync status indicators
4. Handle authentication and permissions

## 📋 User Benefits

1. **Format Flexibility**: Convert to any popular audio format, not just MP3
2. **Quality Control**: Fine-tune sample rate and channels for size vs quality
3. **Automation**: Smart ID3 tagging saves manual metadata entry
4. **Experience**: Haptic feedback provides tactile confirmation
5. **Performance**: Cache management keeps app lightweight
6. **Consistency**: All settings persist across app restarts

## 🎨 UI/UX Highlights

- **Visual Hierarchy**: Clear section grouping with headers
- **Color Coding**: Each category has distinct icon colors
- **Feedback**: Haptic responses on interactions (when enabled)
- **Discoverability**: All options visible without deep navigation
- **Consistency**: Uniform tile design throughout
- **Polish**: Smooth animations and transitions

## ⚠️ Important Notes

1. **FFmpeg Codecs**: Ensure `ffmpeg_kit_flutter_new` includes all required codecs (libopus, libvorbis, etc.). The "full-gpl" variant should include all.

2. **File Extensions**: Update all file naming logic to use the selected format's extension dynamically.

3. **MIME Types**: Use `AudioFormat.mimeType` when sharing files to ensure proper handling.

4. **Testing**: After Phase 1-3 integration, test each format thoroughly:
   - MP3: Most common, should work perfectly
   - AAC/M4A: iOS compatibility
   - OPUS: Best compression, web friendly
   - FLAC/WAV: Lossless quality
   - OGG: Open source, good compression
   - WMA: Windows compatibility

5. **Performance**: Higher sample rates (96/192 kHz) will increase file size and conversion time significantly. Consider adding a warning or explanation.

6. **Default Values**: Current defaults match the reference design:
   - Format: MP3
   - Bitrate: 320 kbps (Maximum)
   - Sample Rate: 44.1 kHz (CD quality)
   - Channel: Stereo

## 🔧 Verification Checklist

Before considering this feature complete:

- [x] All models created and tested
- [x] SettingsProvider extended with new settings
- [x] CacheService implemented
- [x] Settings UI redesigned to match reference
- [x] All strings added to app_strings.dart
- [x] Code formatted and analyzed (0 issues)
- [x] All 88 tests passing
- [ ] FFmpegService updated to support all formats
- [ ] ConversionProvider integrated with new settings
- [ ] File naming uses dynamic extensions
- [ ] Smart ID3 tagging implemented (optional)
- [ ] All formats tested on device
- [ ] User documentation updated

## 📚 Resources

- FFmpeg audio codec documentation: https://ffmpeg.org/ffmpeg-codecs.html
- Audio format comparisons: https://www.makeuseof.com/tag/audio-file-format-right-needs/
- Sample rate guide: https://www.izotope.com/en/learn/digital-audio-basics-sample-rate-and-bit-depth.html

---

**Status**: ✅ **Settings UI Complete** | 🚧 **FFmpeg Integration Pending**

Last updated: 2026-02-07
