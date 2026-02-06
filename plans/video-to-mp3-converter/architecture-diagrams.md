# Visual Architecture & Flow Diagrams

**Project:** MP3 Extract - Video to MP3 Converter  
**Purpose:** Visual reference for understanding app structure and flows

---

## Screen Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         APP LAUNCH (1s)                              │
│                      ┌─────────────┐                                 │
│                      │   Splash    │                                 │
│                      │   Screen    │                                 │
│                      └──────┬──────┘                                 │
│                             │                                        │
│                             ▼                                        │
│                      ┌─────────────┐                                 │
│                      │    Home     │ ◄───────────┐                  │
│                      │   Screen    │             │                  │
│                      └──────┬──────┘             │                  │
│                             │                     │                  │
│         ┌───────────────────┼───────────────────┐│                  │
│         │                   │                   ││                  │
│         ▼                   ▼                   ││                  │
│  ┌─────────────┐     ┌─────────────┐           ││                  │
│  │  Settings   │     │   History   │           ││                  │
│  │   Screen    │     │   Screen    │           ││                  │
│  │             │     │             │           ││                  │
│  │ • Quality   │     │ • All       │           ││                  │
│  │ • Dark Mode │     │ • Today     │           ││                  │
│  │ • Storage   │     │ • Last 7d   │           ││                  │
│  │ • Remove Ads│     │ • High Q    │           ││                  │
│  └─────────────┘     └─────────────┘           ││                  │
│                             │                   ││                  │
│                             │ Tap conversion    ││                  │
│                             ▼                   ││                  │
│         SELECT VIDEO ───────┐                   ││                  │
│                             │                   ││                  │
│                             ▼                   ││                  │
│                      ┌─────────────┐            ││                  │
│                      │ Conversion  │            ││                  │
│                      │  Options    │            ││                  │
│                      │   Screen    │            ││                  │
│                      │             │            ││                  │
│                      │ • Preview   │            ││                  │
│                      │ • Quality   │            ││                  │
│                      │ • Name      │            ││                  │
│                      │ • Estimate  │            ││                  │
│                      └──────┬──────┘            ││                  │
│                             │                   ││                  │
│                    CONVERT NOW                  ││                  │
│                             │                   ││                  │
│                             ▼                   ││                  │
│                      ┌─────────────┐            ││                  │
│                      │ Converting  │            ││                  │
│                      │   Screen    │            ││                  │
│                      │             │            ││                  │
│                      │ • Progress  │            ││                  │
│                      │ • Cancel    │            ││                  │
│                      └──────┬──────┘            ││                  │
│                             │                   ││                  │
│                ┌────────────┴────────────┐      ││                  │
│                ▼                         ▼      ││                  │
│         ┌─────────────┐          ┌─────────────┐│                  │
│         │   Success   │          │    Error    ││                  │
│         │   Screen    │          │   Screen    ││                  │
│         │             │          │             ││                  │
│         │ • Preview   │          │ • Reason    ││                  │
│         │ • Share     │          │ • Retry     ││                  │
│         │ • Convert   │          │ • Select    ││                  │
│         │   Another   │ ─────────┴─────────────┘│                  │
│         └─────────────┘                         │                  │
│                │                                 │                  │
│                └─────────────────────────────────┘                  │
│                    CONVERT ANOTHER / BACK TO HOME                   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│                           USER ACTION                              │
│                        (Tap, Swipe, Type)                         │
└────────────────────────┬──────────────────────────────────────────┘
                         │
                         ▼
┌───────────────────────────────────────────────────────────────────┐
│                         UI LAYER (Dumb)                            │
│                                                                    │
│  Screens:  Home │ Options │ Converting │ Success │ Error │        │
│            History │ Settings │ Empty State                        │
│                                                                    │
│  Widgets:  Buttons │ Cards │ Selectors │ Progress Rings           │
└────────────────────────┬──────────────────────────────────────────┘
                         │
                         │ User Events (onPressed, onChange)
                         │
                         ▼
┌───────────────────────────────────────────────────────────────────┐
│                  STATE MANAGEMENT (Provider)                       │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ ConversionProvider                                           │ │
│  │ • selectVideo() → FilePicker                                │ │
│  │ • startConversion() → FFmpegService                         │ │
│  │ • cancelConversion() → FFmpegService                        │ │
│  │ • State: progress, isConverting, error                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ HistoryProvider                                              │ │
│  │ • loadConversions() → DatabaseService                       │ │
│  │ • applyFilter() → Local filtering                           │ │
│  │ • deleteConversion() → DatabaseService + StorageService     │ │
│  │ • State: conversions[], filter, searchQuery                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ SettingsProvider                                             │ │
│  │ • saveSettings() → SharedPreferences                        │ │
│  │ • loadSettings() → SharedPreferences                        │ │
│  │ • State: defaultQuality, isDarkMode, adsRemoved             │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ AdProvider                                                   │ │
│  │ • loadBannerAd() → AdService                                │ │
│  │ • showInterstitialAd() → AdService                          │ │
│  │ • State: bannerLoaded, interstitialLoaded, adsRemoved       │ │
│  └─────────────────────────────────────────────────────────────┘ │
└────────────────────────┬──────────────────────────────────────────┘
                         │
                         │ Business Logic Calls
                         │
                         ▼
┌───────────────────────────────────────────────────────────────────┐
│                       SERVICE LAYER                                │
│                                                                    │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐        │
│  │ FFmpegService │  │StorageService │  │DatabaseService│        │
│  │               │  │               │  │               │        │
│  │ • convert()   │  │ • saveFile()  │  │ • insert()    │        │
│  │ • cancel()    │  │ • delete()    │  │ • query()     │        │
│  │ • metadata()  │  │ • getPath()   │  │ • delete()    │        │
│  └───────────────┘  └───────────────┘  └───────────────┘        │
│                                                                    │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐        │
│  │PermissionSvc  │  │   AdService   │  │   IapService  │        │
│  │               │  │               │  │               │        │
│  │ • check()     │  │ • loadAd()    │  │ • purchase()  │        │
│  │ • request()   │  │ • showAd()    │  │ • restore()   │        │
│  └───────────────┘  └───────────────┘  └───────────────┘        │
└────────────────────────┬──────────────────────────────────────────┘
                         │
                         │ Data Operations
                         │
                         ▼
┌───────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                  │
│                                                                    │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │   SQLite    │    │   Shared    │    │File System  │          │
│  │  Database   │    │ Preferences │    │             │          │
│  │             │    │             │    │             │          │
│  │ conversions │    │ settings    │    │ Music/      │          │
│  │   table     │    │ adsRemoved  │    │ MP3Conv/    │          │
│  └─────────────┘    └─────────────┘    └─────────────┘          │
│                                                                    │
│  ┌─────────────┐    ┌─────────────┐                              │
│  │   AdMob     │    │Play Billing │                              │
│  │   (Cloud)   │    │   (Cloud)   │                              │
│  │             │    │             │                              │
│  │ • Banner    │    │ • Remove    │                              │
│  │ • Interst.  │    │   Ads IAP   │                              │
│  └─────────────┘    └─────────────┘                              │
└───────────────────────────────────────────────────────────────────┘
```

---

## Conversion Flow (Detailed)

```
USER SELECTS VIDEO
       │
       ▼
┌──────────────────────────────────────────────────────────────┐
│ 1. FilePicker.platform.pickFiles(type: FileType.video)       │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. FFmpegService.getVideoMetadata(videoPath)                 │
│    → Returns: duration, size, codec                          │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. Calculate estimated time                                   │
│    → estimatedTime = duration × 0.2 (multiplier)             │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. Show Conversion Options Screen                            │
│    • Video preview                                            │
│    • File info (name, size, duration)                        │
│    • Quality selector (128/192/320)                          │
│    • Output name input                                        │
│    • "Estimated time: ~XX seconds"                           │
│    • Warning if duration > 30 minutes                        │
└────────────┬─────────────────────────────────────────────────┘
             │
USER TAPS "CONVERT NOW"
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 5. Validate output name                                       │
│    → No special characters, max 50 chars                     │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 6. Get output path                                            │
│    → /storage/emulated/0/Music/MP3Converter/{name}.mp3       │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 7. Start FFmpeg conversion                                    │
│    Command: -i input.mp4 -vn -ar 44100 -ac 2 -b:a 192k out.mp3│
│    → Progress callbacks every 1-2 seconds (0-100%)           │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 8. Show Converting Screen                                     │
│    • Circular progress ring (updates with progress)          │
│    • "Converting..." text                                     │
│    • Estimated time remaining (dynamic)                      │
│    • Cancel button (calls FFmpegService.cancel())            │
└────────────┬─────────────────────────────────────────────────┘
             │
    ┌────────┴────────┐
    ▼                 ▼
 SUCCESS            ERROR
    │                 │
    ▼                 ▼
┌──────────┐    ┌─────────────────────────────────────────────┐
│ SUCCESS  │    │ ERROR HANDLING                               │
│  PATH    │    │ 1. Log error to console                      │
│          │    │ 2. Delete partial MP3 file                   │
│          │    │ 3. Show error screen with reason             │
│          │    │ 4. Offer "Retry" or "Select Another" options │
└──────────┘    └─────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────┐
│ 9. Get file metadata                                          │
│    → size, duration (from converted MP3)                     │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 10. Save to database                                          │
│     INSERT INTO conversions (...)                            │
│     VALUES (name, path, quality, size, duration, timestamp)  │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 11. Show Success Screen                                       │
│     • Checkmark animation (pulse)                            │
│     • File info card                                          │
│     • Audio preview player                                    │
│     • "SHARE FILE" button                                     │
│     • "CONVERT ANOTHER" button                                │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 12. Show Interstitial Ad (if adsRemoved = false)             │
│     → After screen loads, not blocking UI                    │
│     → Respects frequency setting (default: every conversion) │
└────────────┬─────────────────────────────────────────────────┘
             │
USER TAPS "CONVERT ANOTHER"
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 13. Reset ConversionProvider state                            │
│     → Clear selected video, output name, error, progress     │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
      BACK TO HOME SCREEN
```

---

## Ad Display Logic

```
┌─────────────────────────────────────────────────────────────┐
│                      AD DISPLAY LOGIC                        │
└─────────────────────────────────────────────────────────────┘

CHECK: Has user purchased "Remove Ads" IAP?
   │
   ├─ YES → Don't show ANY ads (banner or interstitial)
   │         Exit
   │
   └─ NO → Continue to ad display logic
           │
           ▼
┌───────────────────────────────────────────────────────────────┐
│                      BANNER ADS                                │
│                                                                │
│  Show on:                                                      │
│  ✅ Home Screen (bottom)                                       │
│  ✅ History Screen (bottom)                                    │
│  ✅ Settings Screen (bottom)                                   │
│  ✅ Success Screen (bottom)                                    │
│  ✅ Error Screen (bottom)                                      │
│                                                                │
│  Hide on:                                                      │
│  ❌ Splash Screen (too early)                                  │
│  ❌ Conversion Options (focus on input)                        │
│  ❌ Converting Screen (user focus on progress)                 │
│  ❌ When keyboard is open (covers input)                       │
└───────────────────────────────────────────────────────────────┘
           │
           ▼
┌───────────────────────────────────────────────────────────────┐
│                   INTERSTITIAL ADS                             │
│                                                                │
│  Trigger:                                                      │
│  • After EVERY successful conversion (frequency = 1)          │
│  • NOT after error/cancelled conversion                       │
│  • NOT on app launch                                           │
│                                                                │
│  Timing:                                                       │
│  • Show AFTER Success Screen loads                            │
│  • Non-blocking (user can dismiss)                            │
│  • Preload next ad after dismissal                            │
│                                                                │
│  Configurable:                                                 │
│  • AdConfig.interstitialFrequency = 1                         │
│  • Can change to 2, 3, etc. (show after every X conversions)  │
└───────────────────────────────────────────────────────────────┘

Test Mode vs Production:
┌────────────────────────────────────────────────────────────┐
│ Development: AdConfig.testMode = true                       │
│ • Uses Google's test ad units                              │
│ • No real ads, no revenue                                   │
│ • Safe for testing                                          │
├────────────────────────────────────────────────────────────┤
│ Production: AdConfig.testMode = false                       │
│ • Uses your real AdMob ad unit IDs                         │
│ • Real ads, real revenue                                    │
│ • Set before release                                        │
└────────────────────────────────────────────────────────────┘
```

---

## IAP Purchase Flow

```
USER TAPS "REMOVE ADS & UNLOCK PRO" ($1.99)
       │
       ▼
┌──────────────────────────────────────────────────────────────┐
│ 1. Show loading dialog                                        │
│    "Processing purchase..."                                   │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. IapService.purchaseRemoveAds()                            │
│    → Connects to Play Billing                                │
│    → Shows Google Play purchase dialog                       │
└────────────┬─────────────────────────────────────────────────┘
             │
   ┌─────────┴─────────┐
   ▼                   ▼
SUCCESS            CANCELLED/ERROR
   │                   │
   ▼                   ▼
┌──────────┐    ┌──────────────────────────────────────────────┐
│          │    │ • Dismiss loading dialog                      │
│          │    │ • Show snackbar: "Purchase cancelled/failed"  │
│          │    │ • User can retry                              │
│          │    └──────────────────────────────────────────────┘
│          │
│          ▼
│ ┌──────────────────────────────────────────────────────────┐
│ │ 3. Verify purchase (Google Play receipt)                 │
│ │    → In production: verify with backend server           │
│ │    → For MVP: trust Google Play response                 │
│ └────────────┬─────────────────────────────────────────────┘
│              │
│              ▼
│ ┌──────────────────────────────────────────────────────────┐
│ │ 4. Save purchase status locally                          │
│ │    SharedPreferences.setBool('ads_removed', true)        │
│ └────────────┬─────────────────────────────────────────────┘
│              │
│              ▼
│ ┌──────────────────────────────────────────────────────────┐
│ │ 5. Update SettingsProvider                               │
│ │    SettingsProvider.setAdsRemoved(true)                  │
│ │    → Triggers UI rebuild (hides all ads)                 │
│ └────────────┬─────────────────────────────────────────────┘
│              │
│              ▼
│ ┌──────────────────────────────────────────────────────────┐
│ │ 6. Dismiss loading dialog                                │
│ │    Show success snackbar: "Ads removed successfully!"    │
│ └────────────┬─────────────────────────────────────────────┘
│              │
│              ▼
│        USER SEES NO ADS
│        (Banner and Interstitial hidden)
│
└──────────────────────────────────────────────────────────────┘

RESTORE PURCHASES (For reinstalls):
┌──────────────────────────────────────────────────────────────┐
│ User taps "Restore Purchases" in Settings                    │
│           ▼                                                   │
│ IapService.restorePurchases()                                │
│           ▼                                                   │
│ Play Billing returns previous purchases                      │
│           ▼                                                   │
│ If "remove_ads_v1" found → Save locally + Update provider    │
│           ▼                                                   │
│ Show snackbar: "Purchase restored!"                          │
└──────────────────────────────────────────────────────────────┘
```

---

## Error Handling Flow

```
CONVERSION FAILS
       │
       ▼
┌──────────────────────────────────────────────────────────────┐
│ 1. Catch exception in ConversionProvider                     │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. Identify error type                                        │
│    • FFmpeg returned error code                              │
│    • Invalid video (unsupported codec)                       │
│    • No storage space                                         │
│    • User cancelled                                           │
│    • Unknown error                                            │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. Log technical error to console                            │
│    Logger.error('Conversion failed', error, stackTrace)      │
│    → Full FFmpeg output logged                               │
│    → For debugging only (not shown to user)                  │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. Delete partial MP3 file                                    │
│    StorageService.deleteFile(outputPath)                     │
│    → Prevents corrupted/incomplete files                     │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 5. Map to user-friendly message                              │
│    • Invalid video → "Video format not supported..."         │
│    • No space → "Not enough storage space..."                │
│    • FFmpeg error → "Conversion failed. Please try again."   │
│    • Cancelled → "Conversion cancelled."                     │
│    • Unknown → "Something went wrong..."                     │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────────────┐
│ 6. Navigate to Error Screen                                   │
│    • Show error message (user-friendly)                      │
│    • Show error illustration (broken record)                 │
│    • Offer actions:                                           │
│      - "Retry Conversion" (same video, same settings)        │
│      - "Select Another Video" (back to home)                 │
└────────────┬─────────────────────────────────────────────────┘
             │
USER CHOOSES ACTION
   │
   ├─ RETRY → Go back to Converting Screen
   │           Attempt conversion again
   │
   └─ SELECT ANOTHER → Navigate to Home
                       Reset ConversionProvider state
```

---

## File Structure Visual

```
/Users/mahendra/work-dir/p-project/call-assitant/
│
├── android/                          # Android platform code
│   ├── app/
│   │   ├── build.gradle             # Build config (minSdk, targetSdk)
│   │   ├── proguard-rules.pro       # ProGuard for release
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  # Permissions, AdMob ID
│   │       └── kotlin/.../MainActivity.kt
│   └── build.gradle                  # Project-level gradle
│
├── lib/                              # Dart source code
│   ├── main.dart                     # Entry point
│   ├── app.dart                      # MaterialApp + Theme + Routes
│   │
│   ├── constants/                    # All constants (no logic)
│   │   ├── app_colors.dart          # Color(0xFF...)
│   │   ├── app_strings.dart         # Static strings
│   │   ├── app_constants.dart       # Magic numbers, ad config
│   │   └── app_theme.dart           # ThemeData
│   │
│   ├── models/                       # Data classes (immutable)
│   │   ├── audio_quality.dart       # Enum: low128, medium192, high320
│   │   ├── conversion_task.dart     # Input, output, progress, status
│   │   └── audio_file.dart          # Filename, path, size, duration
│   │
│   ├── providers/                    # ChangeNotifier (state)
│   │   ├── conversion_provider.dart # Video selection, conversion state
│   │   ├── history_provider.dart    # Conversions list, filters
│   │   ├── settings_provider.dart   # App settings, theme, IAP status
│   │   └── ad_provider.dart         # Ad loading, display logic
│   │
│   ├── services/                     # Business logic (pure functions)
│   │   ├── ffmpeg_service.dart      # FFmpeg commands, progress
│   │   ├── storage_service.dart     # File I/O, paths
│   │   ├── database_service.dart    # SQLite CRUD
│   │   ├── permission_service.dart  # Android permissions
│   │   ├── ad_service.dart          # AdMob wrapper
│   │   └── iap_service.dart         # In-app purchase wrapper
│   │
│   ├── screens/                      # UI (dumb widgets)
│   │   ├── splash_screen.dart       # 1 second, auto-navigate
│   │   ├── home_screen.dart         # Hero button + recent conversions
│   │   ├── conversion_options_screen.dart # Quality + name + estimate
│   │   ├── converting_screen.dart   # Progress ring + cancel
│   │   ├── success_screen.dart      # Preview + share + convert another
│   │   ├── error_screen.dart        # Error message + retry
│   │   ├── history_screen.dart      # Filters + search + list
│   │   └── settings_screen.dart     # Settings + Remove Ads
│   │
│   ├── widgets/                      # Reusable components
│   │   ├── common/
│   │   │   ├── primary_button.dart  # 56dp, #2563EB, full width
│   │   │   ├── secondary_button.dart # Outlined style
│   │   │   ├── quality_selector.dart # 3 toggle buttons
│   │   │   ├── progress_ring.dart   # Circular progress
│   │   │   ├── conversion_card.dart # List item (72dp)
│   │   │   └── empty_state.dart     # Illustration + message + CTA
│   │   └── audio/
│   │       ├── audio_preview_player.dart # Play/pause/seek
│   │       └── waveform_visualizer.dart  # (optional)
│   │
│   └── utils/                        # Helper functions
│       ├── file_utils.dart          # formatFileSize(), getExtension()
│       ├── format_utils.dart        # formatDuration(), formatDate()
│       ├── validation_utils.dart    # validateOutputName()
│       └── logger.dart               # Logger.info(), Logger.error()
│
├── test/                             # Unit + widget tests
│   ├── services/                     # Test each service
│   ├── providers/                    # Test state management
│   ├── widgets/                      # Test components
│   └── screens/                      # Test screens
│
├── pubspec.yaml                      # Dependencies
├── analysis_options.yaml             # Lint rules
└── README.md                         # Project overview
```

---

**END OF VISUAL DIAGRAMS**

These diagrams provide a high-level overview. Refer to other docs for detailed specs.
