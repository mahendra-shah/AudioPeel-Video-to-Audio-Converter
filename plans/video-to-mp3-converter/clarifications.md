# Design & Feature Clarifications

**Date:** 6 February 2026  
**Status:** Finalized based on client feedback

---

## Design Mapping (18 Images = 9 Screens × 2 Modes)

Based on screenshots provided:

### Image 1-2: Home Screen (Light + Dark)
- Large "SELECT VIDEO" circular button with gradient
- Recent Conversions list (3-4 items)
- Banner ad at bottom
- **NO bottom navigation** (removed per decision)

### Image 3-4: Conversion Options (Light + Dark)
- Video preview card with play button overlay
- File info (filename, size, duration)
- Quality selector: 128 | 192 | 320 kbps
- Output name input field
- "CONVERT NOW" button

### Image 5: Conversion Progress (Dark only)
- Large circular progress ring (65%)
- "Converting..." text
- Filename and estimated time
- Linear progress bar below
- Cancel button

### Image 6: Success Screen (Light)
- Green checkmark icon with pulse animation
- "Conversion Complete!" message
- Waveform preview
- File info card
- "SHARE FILE" and "CONVERT ANOTHER" buttons
- Interstitial ad shown after screen loads

### Image 7-8: Settings (Dark + Light)
- "Remove Ads & Unlock Pro" highlighted button (#F59E0B)
- Audio Settings (Default Quality)
- General (Dark Mode, Auto-delete Source)
- Storage (Output Path, Clear Cache)
- About (Version, Privacy Policy)

### Image 9-10: Empty State (Light + Dark)
- App icon illustration
- "No conversions yet" message
- "SELECT VIDEO" button
- Used when history is empty

### Image 11: Error State (Dark)
- Broken record vinyl illustration
- "Something went wrong" message
- User-friendly error text
- "Retry Conversion" and "Select Another Video" buttons

### Image 12-13: History Screen (Light + Dark)
- Filter tabs: All | Today | Last 7 Days | High Quality
- Search bar
- Conversions grouped by date
- Each item: thumbnail, filename, size, duration, date
- Swipe to delete

### Image 14-18: Batch Conversion Screens (PHASE 2 - Deferred)
- Batch selection screen (multiple videos)
- Batch progress screen (queue with statuses)
- Batch completion screen
- **Decision:** Not implementing in MVP (Phase 2 feature)

---

## Feature Decisions Summary

### 1. Bottom Navigation: **REMOVED**
**Rationale:**
- Maximizes vertical space for conversions and ads
- Simplifies navigation (fewer taps)
- Settings accessible via top-right icon
- History accessible via "See All" link from Home

**New Navigation Flow:**
```
Home (default)
├── Settings (top-right icon)
├── History (See All link or scroll up from recent conversions)
└── Conversion Flow (Select Video → Options → Progress → Success/Error)
```

### 2. Batch Conversion: **Phase 2**
**Rationale:**
- Adds significant complexity (queue management, parallel processing)
- Not critical for MVP user experience
- Can be added post-launch based on user demand
- Faster time to market without it

**Phase 1:** Single video conversion only  
**Phase 2:** Batch processing with device-based parallelization

### 3. Recent Conversions on Home: **3-4 items with fade effect**
**Implementation:**
- Show 3-4 most recent conversions (based on available space)
- Last item has fade gradient overlay if more conversions exist
- Tapping fade overlay OR scroll-up gesture → navigates to History
- "See All" link always visible if conversions > 0

### 4. History Filters: **All included in Phase 1**
**Filters:**
- ✅ All
- ✅ Today
- ✅ Last 7 Days
- ✅ High Quality (320 kbps)

**Search:** ✅ By filename with debouncing (300ms)

### 5. Audio Preview: **Basic playback only**
**Features:**
- Play/Pause button
- Seek bar (timeline scrubbing)
- Current time / Total duration display
- **Optional:** Static waveform visualization (can use placeholder image)

**NOT included:** Advanced audio editing, trimming, effects (Phase 2)

### 6. Parallel Processing: **Sequential for MVP**
**Decision:** Single conversion at a time in Phase 1

**Rationale:**
- Simpler implementation (no queue management)
- Works on all devices (no performance detection needed)
- Easier testing and debugging
- Most users convert 1-2 videos at a time

**Phase 2:** Device-based parallel processing:
- Low-end: 1 at a time (sequential)
- Mid-range: 2-3 parallel instances
- High-end: 4-5 parallel instances
- Detect via: RAM, CPU cores, benchmarking

### 7. Video Length: **No hard limit**
**Policy:**
- Accept ANY video length (user freedom)
- Show estimated time BEFORE conversion
- Warn if video > 30 minutes: "Large file - conversion may take a while"
- Don't block conversion (user decides)

**Example Warnings:**
- 30-60 min: "This may take 2-5 minutes"
- 60+ min: "This may take 5-10 minutes"
- 2+ hours: "This may take 10-20 minutes"

### 8. Error Handling: **Log + Delete Partial**
**On Conversion Failure:**
1. Delete partially converted MP3 file automatically
2. Log technical error to console (FFmpeg output)
3. Show user-friendly message based on error type:
   - **Invalid video:** "Video format not supported. Try a different file."
   - **No space:** "Not enough storage space. Free up some space and try again."
   - **FFmpeg error:** "Conversion failed. Please try again."
   - **Unknown:** "Something went wrong. Please check your file and try again."
4. Offer "Retry" and "Select Another Video" options

### 9. "Convert Another" Button: **Keep it**
**Rationale:**
- Clear call-to-action for repeat usage
- More discoverable than back button
- Resets state cleanly (avoids stale data)
- Standard pattern in conversion apps

**Alternatives still available:**
- Top-left back arrow
- System back gesture
- Both navigate to Home but don't reset state

### 10. Settings "Remove Ads" Button: **Intentionally Highlighted**
**Design:**
- Different color: #F59E0B (orange/amber)
- Larger than other settings items
- Icon: Crown/star (premium feel)
- Price visible: "$1.99"

**Animation:** Subtle glow/pulse effect (optional)
- Use `flutter_animate` package
- Gentle scale pulse (1.0 → 1.02 → 1.0) every 3 seconds
- Don't overdo it (avoid annoyance)

### 11. Tech Stack Package Verification: **Required**
**Important Note:** Some packages in system instructions may be outdated/incorrect.

**Verified Packages (as of Feb 2026):**
- ✅ `provider: ^6.1.2`
- ✅ `ffmpeg_kit_flutter: ^6.0.3` (NOT `ffmpeg_kit_flutter_new`)
- ✅ `permission_handler: ^11.3.1`
- ✅ `path_provider: ^2.1.4`
- ✅ `file_picker: ^8.0.5`
- ✅ `google_mobile_ads: ^5.1.0`
- ✅ `in_app_purchase: ^3.2.0`
- ✅ `sqflite: ^2.3.3+1`
- ✅ `shimmer: ^3.0.0`
- ✅ `flutter_animate: ^4.5.0`
- ✅ `intl: ^0.19.0`
- ✅ `shared_preferences: ^2.3.2`

**Action:** During implementation, verify EACH package on pub.dev before adding to `pubspec.yaml`.

### 12. Share Functionality: **Both Options**
**On Success Screen "SHARE FILE" button:**
- Show system share sheet with TWO options:
  1. **Share File:** Share MP3 file directly (WhatsApp, Gmail, Drive, etc.)
  2. **Share Location:** Share text with file path (for users who want to know where it's saved)

**Implementation:**
```dart
// Option 1: Share file
Share.shareFiles([audioFilePath], text: 'Check out this audio!');

// Option 2: Share location (fallback)
Share.share('Audio saved to: $audioFilePath');
```

### 13. Ad Frequency: **Configurable**
**Interstitial Ads:**
- Show after EVERY conversion (default frequency = 1)
- Configurable via constant: `AdConfig.interstitialFrequency = 1`
- Stored in `lib/constants/app_constants.dart`
- Can be changed via remote config (future: Firebase Remote Config)

**Why configurable:**
- Easy to adjust based on user feedback
- Can reduce frequency in future updates (e.g., every 2 or 3 conversions)
- Can A/B test different frequencies

**Banner Ads:**
- Persistent on: Home, History, Settings, Success, Error
- Hidden on: Conversion Progress (user focus)
- Hidden on: Splash (too early)

**Interstitial = Full-screen video/image ads**  
**Banner = Small 50dp strip at bottom**

Correct understanding confirmed! ✅

### 14. Banner Ads + Keyboard: **Hide banner when keyboard open**
**Implementation:**
```dart
// Detect keyboard visibility
final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

// Conditionally show banner
if (!isKeyboardOpen) {
  BannerAdWidget();
}
```

**Rationale:**
- Prevents banner from covering input fields
- Better UX during text entry
- Re-shows when keyboard closes

### 15. Error State Display: **Show error reason + cleanup**
**On Error Screen:**
- **User-Facing Message:** Generic but helpful (e.g., "Video format not supported")
- **Console Log:** Full FFmpeg error output (for debugging)
- **Action:** Delete partially converted MP3 file automatically
- **Options:** "Retry Conversion" | "Select Another Video"

**Error Categories:**
1. **Invalid Video:** Unsupported codec, corrupted file
2. **No Space:** Storage full
3. **FFmpeg Error:** Conversion process failed
4. **Cancelled:** User cancelled mid-conversion
5. **Unknown:** Unexpected error

### 16. Video Length & Time Estimation: **Always show estimate**
**Flow:**
1. User selects video
2. App reads video metadata (FFmpeg)
3. Calculate estimated time based on:
   - Video duration
   - Selected quality (128/192/320)
   - Device performance (rough estimate)
4. Show on Conversion Options screen: "Estimated time: ~15 seconds"
5. If video > 30 minutes, show warning: "Large file detected. Conversion may take 5-10 minutes."
6. Don't block conversion (user decides whether to proceed)

**Estimation Formula:**
```dart
int estimateConversionTime(int videoDurationSeconds, AudioQuality quality) {
  // Rough formula: conversion takes ~0.2x video duration
  // Adjust multiplier based on quality
  double multiplier = quality == AudioQuality.high320 ? 0.25 : 0.20;
  return (videoDurationSeconds * multiplier).round();
}
```

**Standard:** Show estimate for EVERY video before conversion.

---

## Final Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
├─────────────────────────────────────────────────────────────┤
│  Screens:                                                    │
│  • Home (no bottom nav)                                      │
│  • Conversion Options (with estimated time)                  │
│  • Converting (progress with cancel)                         │
│  • Success (share file + location)                           │
│  • Error (reason + retry)                                    │
│  • History (filters: All/Today/Week/HQ)                      │
│  • Settings (highlighted Remove Ads)                         │
│  • Empty State (onboarding)                                  │
├─────────────────────────────────────────────────────────────┤
│                    State Management                          │
│                     (Provider)                               │
├─────────────────────────────────────────────────────────────┤
│  Providers:                                                  │
│  • ConversionProvider (single video, sequential)            │
│  • HistoryProvider (all filters in Phase 1)                 │
│  • SettingsProvider (Remove Ads flag)                       │
│  • AdProvider (frequency = 1, configurable)                 │
├─────────────────────────────────────────────────────────────┤
│                      Service Layer                           │
├─────────────────────────────────────────────────────────────┤
│  Services:                                                   │
│  • FFmpegService (video metadata + conversion)              │
│  • StorageService (file I/O, delete partial)                │
│  • DatabaseService (SQLite history)                          │
│  • PermissionService (Android 8-9 only)                     │
│  • AdService (AdMob: banner + interstitial)                 │
│  • IapService (Remove Ads $1.99)                            │
├─────────────────────────────────────────────────────────────┤
│                       Data Layer                             │
├─────────────────────────────────────────────────────────────┤
│  • SQLite Database (unlimited history)                       │
│  • SharedPreferences (settings, IAP status)                  │
│  • File System (output MP3s)                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Open Questions: **ALL RESOLVED ✅**

All clarifications provided. Ready to proceed with implementation!

---

## Next Steps

1. **Review this document** - Confirm all decisions are correct
2. **Start Step 1** - Project setup & architecture foundation
3. **Iterate through Steps 2-20** - Follow plan.md commit-by-commit
4. **Request design screenshots** - When implementing each screen, ask for specific design image
5. **Test continuously** - Run tests after each step
6. **Launch preparation** - Steps 19-20 for production release

**Estimated Timeline:** 6-9 weeks (solo developer, part-time)

---

**Status:** ✅ Planning Complete - Ready for Implementation
