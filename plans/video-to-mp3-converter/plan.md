# MP3 Extract - Video to MP3 Converter App

**Branch:** `feature/video-to-mp3-converter-mvp`  
**Description:** Production-ready video to MP3 converter with offline conversion, quality selection, history tracking, and monetization.

---

## Goal

Build a complete, production-ready Android utility app that converts videos to MP3 files with blazing-fast FFmpeg processing. The app prioritizes simplicity (60-second first conversion), privacy (no login/cloud), and fair monetization (ads + optional IAP). Target users who want quick, reliable video-to-audio extraction without complexity.

**Key Differentiators:**
- True offline functionality (no internet required)
- No account/login/cloud - 100% local processing
- Simplified navigation (no bottom nav - more space for content)
- Fair monetization (non-intrusive ads + $1.99 Remove Ads)
- Blazing fast FFmpeg conversion (native speed)

---

## Implementation Steps

This is a **COMPLEX** feature requiring multiple commits. Each step is testable and brings the app closer to production-ready state.

---

### Step 1: Project Setup & Architecture Foundation

**Files:**
- `pubspec.yaml` (create)
- `lib/main.dart` (create)
- `lib/app.dart` (create)
- `lib/constants/app_colors.dart` (create)
- `lib/constants/app_strings.dart` (create)
- `lib/constants/app_constants.dart` (create)
- `lib/constants/app_theme.dart` (create)
- `analysis_options.yaml` (create)
- `android/app/build.gradle` (modify)
- `android/app/src/main/AndroidManifest.xml` (modify)

**What:**  
Initialize Flutter project with Material 3, setup color system (light/dark themes), configure Android permissions (storage for API <29), add all required dependencies (provider, ffmpeg_kit_flutter, file_picker, path_provider, permission_handler, google_mobile_ads, in_app_purchase, sqflite, shimmer, flutter_animate, intl, shared_preferences). Configure ProGuard rules for FFmpeg. Setup app constants (ad frequency, quality options, file paths).

**Key Technical Decisions:**
- Min SDK: 26 (Android 8.0) - 99%+ coverage
- Target SDK: 34 (Android 14)
- FFmpeg Package: `ffmpeg_kit_flutter` (not `ffmpeg_kit_flutter_new` - verify on pub.dev)
- Theme: Dark mode default, Material 3
- No bottom navigation (simplified)

**Testing:**  
- Run `flutter pub get` successfully
- Run `flutter analyze` with zero errors
- Run empty app on Android emulator/device
- Verify dark/light theme switching
- Verify Material 3 components rendering

---

### Step 2: Data Models & Database Setup

**Files:**
- `lib/models/audio_quality.dart` (create)
- `lib/models/conversion_task.dart` (create)
- `lib/models/audio_file.dart` (create)
- `lib/services/database_service.dart` (create)
- `test/services/database_service_test.dart` (create)

**What:**  
Create immutable data models for audio quality enum (128/192/320 kbps), conversion task (input video, output path, status, progress, error), and audio file (filename, path, size, duration, quality, timestamp). Implement SQLite database service with tables for conversion history. Include CRUD operations: insert conversion, update status/progress, get all conversions, get filtered (today/last 7 days/high quality), delete conversion, clear all. Use proper error handling and null safety.

**Database Schema:**
```sql
CREATE TABLE conversions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  input_video_name TEXT NOT NULL,
  input_video_path TEXT NOT NULL,
  output_audio_name TEXT NOT NULL,
  output_audio_path TEXT NOT NULL,
  quality INTEGER NOT NULL, -- 128, 192, 320
  file_size INTEGER NOT NULL, -- in bytes
  duration INTEGER NOT NULL, -- in seconds
  status TEXT NOT NULL, -- 'completed', 'failed'
  created_at INTEGER NOT NULL, -- Unix timestamp
  error_message TEXT -- null if successful
);
```

**Testing:**
- Unit test database CRUD operations
- Test filtering logic (today, last 7 days, high quality)
- Test database upgrade/migration
- Verify null safety and error handling

---

### Step 3: Core Services - FFmpeg, Storage, Permissions

**Files:**
- `lib/services/ffmpeg_service.dart` (create)
- `lib/services/storage_service.dart` (create)
- `lib/services/permission_service.dart` (create)
- `lib/utils/file_utils.dart` (create)
- `lib/utils/format_utils.dart` (create)
- `test/services/ffmpeg_service_test.dart` (create)
- `test/services/storage_service_test.dart` (create)

**What:**  
Implement FFmpeg service with methods: `convertVideoToMP3(inputPath, outputPath, quality, onProgress)`, `cancelConversion()`, `getVideoMetadata(path)` for duration/size, `estimateConversionTime(videoPath, quality)`. Implement storage service: `getOutputDirectory()`, `saveAudioFile()`, `deleteFile()`, `getFileSize()`, `createDirectory()`. Implement permission service for Android 8-9 legacy storage permissions. Include progress callbacks (0-100%), error handling, partial file cleanup on failure/cancellation.

**FFmpeg Command:**
```dart
// For 192 kbps MP3
final command = '-i $inputPath -vn -ar 44100 -ac 2 -b:a 192k $outputPath';
```

**Key Implementation Notes:**
- Use `ffmpeg_kit_flutter` (verify exact package name on pub.dev)
- Progress updates every 1-2 seconds
- Cancel via FFmpeg session ID
- Delete partial files on error/cancel
- Log FFmpeg errors to console (not UI)

**Testing:**
- Unit test storage operations (mocked file system)
- Unit test permission checks (mocked platform)
- Integration test FFmpeg conversion with sample video
- Test cancellation mid-conversion
- Test error handling (invalid video, no space)

---

### Step 4: State Management - Providers

**Files:**
- `lib/providers/conversion_provider.dart` (create)
- `lib/providers/history_provider.dart` (create)
- `lib/providers/settings_provider.dart` (create)
- `test/providers/conversion_provider_test.dart` (create)
- `test/providers/history_provider_test.dart` (create)

**What:**  
Create `ConversionProvider` extending `ChangeNotifier` with state: selectedVideo, outputName, selectedQuality, conversionProgress, isConverting, estimatedTime, error. Methods: `selectVideo()`, `updateOutputName()`, `selectQuality()`, `startConversion()`, `cancelConversion()`, `reset()`. Create `HistoryProvider` with state: conversions list, filter (all/today/week/highQuality), searchQuery. Methods: `loadConversions()`, `applyFilter()`, `searchByName()`, `deleteConversion()`, `clearAll()`. Create `SettingsProvider` with state: defaultQuality, isDarkMode, autoDeleteSource, outputFolder, adsRemoved. Methods: `saveSettings()`, `loadSettings()`.

**Provider Lifecycle:**
- Use `SharedPreferences` for settings persistence
- Use `DatabaseService` for history
- Use `FFmpegService` for conversions
- Proper error handling and loading states

**Testing:**
- Unit test all provider methods
- Test state updates trigger `notifyListeners()`
- Test async operations (loading, saving)
- Test error scenarios

---

### Step 5: Reusable Widgets & Components

**Files:**
- `lib/widgets/common/primary_button.dart` (create)
- `lib/widgets/common/secondary_button.dart` (create)
- `lib/widgets/common/quality_selector.dart` (create)
- `lib/widgets/common/progress_ring.dart` (create)
- `lib/widgets/common/conversion_card.dart` (create)
- `lib/widgets/common/empty_state.dart` (create)
- `lib/widgets/audio/audio_preview_player.dart` (create)
- `test/widgets/primary_button_test.dart` (create)
- `test/widgets/quality_selector_test.dart` (create)

**What:**  
Build design system components matching exact specifications:

1. **PrimaryButton:** 56dp height, 16dp radius, full width, #2563EB background, white text (Inter SemiBold 15sp UPPERCASE), optional icon, shadow, scale animation on press.

2. **SecondaryButton:** Same as primary but outlined style (transparent background, 1dp border).

3. **QualitySelector:** 3 equal-width toggle buttons (128/192/320), 48dp height, selected state with primary color, unselected with surface color + border.

4. **ProgressRing:** Circular progress indicator, 200dp diameter, 12dp stroke, percentage in center (Poppins Bold 48sp), custom color.

5. **ConversionCard:** 72dp height, 12dp radius, shows thumbnail/icon + filename + size/duration + action button (share/delete).

6. **EmptyState:** Illustration + title + subtitle + CTA button, vertically centered.

7. **AudioPreviewPlayer:** Basic play/pause/seek controls, waveform visualization (optional), duration display.

All widgets must:
- Use const constructors where possible
- Follow 48x48dp minimum touch targets
- Use colors from `app_colors.dart`
- Use strings from `app_strings.dart`
- Be fully accessible (semantic labels)

**Testing:**
- Widget tests for each component
- Test interactions (button press, selector change)
- Test accessibility (semantic labels)
- Test theming (light/dark mode)

---

### Step 6: Home Screen (Core UI)

**Files:**
- `lib/screens/home_screen.dart` (create)
- `test/screens/home_screen_test.dart` (create)

**What:**  
Build Home Screen UI per design specs:
- **Top Bar (64dp):** "MP3 Extract" title (left), Settings icon (right)
- **Hero Section (240dp):** Large circular button (200dp) with gradient (#3B82F6 to #2563EB), video icon + "SELECT VIDEO" text, subtitle below
- **Recent Conversions Section:** "Recent Conversions" header with "See All" link, shows 3-4 latest conversions using `ConversionCard` widgets, fade effect on last item if more exist
- **Empty State:** If no conversions, show `EmptyState` widget with "No conversions yet" message
- **Banner Ad:** 50dp height at bottom (AdMob banner)
- **Behavior:** Tapping hero button opens file picker, "See All" navigates to History Screen, tapping conversion card navigates to Success Screen (preview mode)

**Integration:**
- Use `Provider.of<HistoryProvider>` for conversion list
- Use `Provider.of<ConversionProvider>` for video selection
- Use `FilePicker.platform.pickFiles(type: FileType.video)`

**Testing:**
- Widget test screen rendering
- Test empty state vs data state
- Test file picker invocation (mocked)
- Test navigation to History/Success screens
- Test ad display (test mode)

---

### Step 7: Conversion Options Screen

**Files:**
- `lib/screens/conversion_options_screen.dart` (create)
- `test/screens/conversion_options_screen_test.dart` (create)

**What:**  
Build Conversion Options Screen per design:
- **Top Bar:** Back arrow (left), "Conversion Options" title (center)
- **Video Preview Card:** 16:9 aspect ratio, rounded 16dp, thumbnail placeholder, play button overlay (64dp)
- **File Info Card:** Displays filename, size, duration from selected video
- **Quality Selection:** "Audio Quality (kbps)" header + `QualitySelector` widget (default 192 kbps from settings)
- **Output Name Input:** "Output Name" header + text field (52dp height, 12dp radius), pre-filled with "{filename}_audio", validation (max 50 chars, no special chars)
- **Estimated Time:** "Estimated time: ~XX seconds" (calculated based on video duration + quality)
- **Warning:** If video > 30 minutes, show warning banner "Large file - conversion may take a while" (yellow background)
- **Convert Button:** Primary button at bottom "CONVERT NOW" with lightning bolt icon

**Integration:**
- Get video metadata using `FFmpegService.getVideoMetadata()`
- Calculate estimated time using `FFmpegService.estimateConversionTime()`
- Validate output name (no `/`, `\`, `*`, `?`, `:`, `|`, `<`, `>`, `"`)
- On "Convert Now": navigate to Converting Screen + start conversion

**Testing:**
- Test metadata extraction (mocked)
- Test estimated time calculation
- Test output name validation
- Test warning display for large videos
- Test navigation on button press

---

### Step 8: Converting Screen (Progress)

**Files:**
- `lib/screens/converting_screen.dart` (create)
- `test/screens/converting_screen_test.dart` (create)

**What:**  
Build Converting Screen per design (dark mode only):
- **Top Bar:** Back arrow (left) disabled during conversion, "Conversion" title
- **Centered Content:**
  - `ProgressRing` widget (200dp, shows percentage 0-100%)
  - "Converting..." text below (Poppins Medium 16sp)
  - Filename display (Body text, secondary color)
  - "Estimated time: XX seconds" (Caption, secondary color, updates dynamically)
- **Linear Progress Bar:** Full width below ring (4dp height, 16dp radius)
- **Overall Progress Label:** "OVERALL PROGRESS" + "XX/100" (top-right of progress bar)
- **Cancel Button:** Text button at bottom "Cancel Conversion" (secondary color)
- **No Ads:** Banner ad hidden during conversion (user focus)

**Integration:**
- Listen to `ConversionProvider.conversionProgress` (0-100)
- Update UI every 1-2 seconds
- On success: navigate to Success Screen
- On error: navigate to Error Screen
- On cancel: delete partial file + navigate back to Home
- Show loading indicator on back press (warns user about cancellation)

**Behavior:**
- Back button shows "Cancel conversion?" dialog
- System back gesture shows same dialog
- App killed: conversion continues in background (WorkManager)

**Testing:**
- Test progress updates (mocked)
- Test success navigation
- Test error navigation
- Test cancellation flow
- Test back button dialog

---

### Step 9: Success Screen

**Files:**
- `lib/screens/success_screen.dart` (create)
- `test/screens/success_screen_test.dart` (create)

**What:**  
Build Success Screen per design:
- **Top Bar:** Back arrow (left), close icon (right)
- **Centered Content:**
  - Large checkmark icon (80dp, #10B981, animated pulse on appear)
  - "Conversion Complete!" (Display text, Poppins Bold 24sp)
  - "Your file is ready to use" (Body text, secondary color)
- **Waveform Preview Card:** 16:9 ratio, rounded 16dp, waveform visualization (can use `flutter_animate` for simple animation or static placeholder)
- **File Info Card:** 
  - Filename: "summer_vacation_audio.mp3"
  - Location: "/Internal Storage/Music/MP3Converter/"
  - Size: "14.2 MB"
  - Duration: "03:45"
- **Audio Preview:** `AudioPreviewPlayer` widget (play/pause/seek)
- **Action Buttons:**
  - Primary: "SHARE FILE" button (full width, with share icon)
  - Secondary: "CONVERT ANOTHER" button (full width, outlined, with refresh icon)
- **Interstitial Ad:** Show AFTER screen loads (configurable frequency via env)
- **Banner Ad:** 50dp at bottom

**Integration:**
- Get audio file info from `ConversionProvider` result
- Share file using native share sheet (`Share.shareFiles([audioPath])`)
- "Convert Another" clears `ConversionProvider` state + navigates to Home
- Add conversion to history database
- Show interstitial ad (respects "Remove Ads" IAP)

**Testing:**
- Test file info display
- Test audio preview player
- Test share functionality (mocked)
- Test "Convert Another" navigation + state reset
- Test ad display logic (test mode + removed ads flag)

---

### Step 10: Error Screen

**Files:**
- `lib/screens/error_screen.dart` (create)
- `test/screens/error_screen_test.dart` (create)

**What:**  
Build Error Screen per design (dark mode):
- **Top Bar:** Back arrow, "Conversion Error" title
- **Centered Content:**
  - Error illustration (broken record vinyl, 200dp) - can use asset or icon
  - "Something went wrong" (Display text, Poppins Bold 24sp, white)
  - Error message (Body text, secondary color) - user-friendly version:
    - "We encountered an issue while converting your video"
    - "Please check your internet connection and try again" (generic message)
  - Technical error logged to console (FFmpeg error, file not found, no space, etc.)
- **Action Buttons:**
  - Primary: "Retry Conversion" (full width, with retry icon)
  - Secondary: "Select Another Video" (full width, outlined)
- **Error Handling:**
  - Delete partial file automatically
  - Log error to console/Crashlytics
  - Show different messages based on error type:
    - No space: "Not enough storage space"
    - Invalid video: "Video format not supported"
    - FFmpeg error: "Conversion failed"
    - Unknown: "Something went wrong"

**Integration:**
- Get error from `ConversionProvider.error`
- "Retry" attempts conversion again with same settings
- "Select Another" navigates to Home + clears error state
- Banner ad at bottom (no interstitial on error screen)

**Testing:**
- Test error message display
- Test partial file deletion
- Test retry functionality
- Test navigation

---

### Step 11: History Screen

**Files:**
- `lib/screens/history_screen.dart` (create)
- `test/screens/history_screen_test.dart` (create)

**What:**  
Build History Screen per design:
- **Top Bar:** Back arrow, "Conversion History" title, kebab menu (right) for "Clear All"
- **Filter Tabs:** Horizontal scrollable tabs: "All" | "Today" | "Last 7 Days" | "High Quality" (320 kbps)
- **Search Bar:** 52dp height, 12dp radius, search icon + hint text "Search converted files"
- **Conversion List:** 
  - Grouped by date: "TODAY", "YESTERDAY", "LAST 7 DAYS"
  - Each item uses `ConversionCard` widget
  - Shows: thumbnail/icon, filename, duration + size, date/time
  - Swipe actions: Delete (right swipe, red background)
  - Tap: Navigate to Success Screen (preview mode)
- **Empty State:** If filtered list empty, show "No conversions found" with icon
- **Banner Ad:** 50dp at bottom

**Integration:**
- Use `HistoryProvider` for data + filtering
- Implement search with debouncing (300ms delay)
- Group conversions by date logic
- Delete confirmation dialog on swipe
- Refresh list on return from Success Screen

**Testing:**
- Test filtering logic (all filters)
- Test search functionality
- Test grouping by date
- Test delete with confirmation
- Test empty states for each filter

---

### Step 12: Settings Screen

**Files:**
- `lib/screens/settings_screen.dart` (create)
- `test/screens/settings_screen_test.dart` (create)

**What:**  
Build Settings Screen per design:
- **Top Bar:** Back arrow, "Settings" title
- **Sections (with spacing):**

**1. Remove Ads (Highlighted)**
- Large button (full width, #F59E0B background, white text)
- Icon: Crown/star icon
- Text: "Remove Ads & Unlock Pro"
- Price: "$1.99" (right side)

**2. Audio Configuration**
- Default Quality: "High (192kbps)" → Opens quality selector dialog
- Format: "MP3" (fixed, grayed out - future: AAC, FLAC)

**3. General**
- Dark Mode: Toggle switch (ON/OFF)
- Auto-delete Source: Toggle (default OFF) - "Remove video after conversion"

**4. Storage**
- Output Folder: Shows current path → Opens folder picker
- Clear Cache: Shows cache size (e.g., "24 MB") → Confirmation dialog

**5. About**
- Version: "v1.0.0 (Build 42)"
- Privacy Policy: External link icon → Opens browser
- Support & Feedback: Email icon → Opens email client

**Integration:**
- Use `SettingsProvider` for all settings
- IAP integration: `InAppPurchase.instance.buyNonConsumable(removeAdsProductId)`
- Folder picker: Use `file_picker` package
- Clear cache: Delete converted files + temporary files
- Privacy policy: Use `url_launcher` package

**Testing:**
- Test IAP purchase flow (sandbox mode)
- Test settings persistence (SharedPreferences)
- Test folder picker (mocked)
- Test cache clearing
- Test external links

---

### Step 13: Empty State & Splash Screen

**Files:**
- `lib/screens/empty_state_screen.dart` (create)
- `lib/screens/splash_screen.dart` (create)
- `test/screens/splash_screen_test.dart` (create)

**What:**  

**Splash Screen (1 second max):**
- App logo (120x120dp, rounded 24dp, gradient blue)
- App name: "MP3 Extract" (Poppins SemiBold 24sp)
- Tagline: "Extract Audio in Seconds" (Inter 14sp, secondary color)
- Bottom badges: "Offline • Free • No Account" (Inter 12sp)
- Dark background (#0F172A) with subtle gradient
- Auto-navigate to Home after 1 second

**Empty State Screen:**
- Used in Home Screen when no conversions exist
- Illustration: Music note icon (120dp, gradient blue circle)
- Title: "No conversions yet" (Poppins SemiBold 20sp)
- Subtitle: "Your converted files will appear here. Start by selecting a video!" (Inter 14sp, secondary color)
- Primary button: "SELECT VIDEO"

**Integration:**
- Splash checks for first launch (shows onboarding if needed - future)
- Preload: Initialize database, load settings, check IAP status
- Empty state integrated into Home Screen conditionally

**Testing:**
- Test splash screen timing (1 second)
- Test navigation to Home
- Test empty state rendering
- Test button action

---

### Step 14: Ad Integration (AdMob)

**Files:**
- `lib/services/ad_service.dart` (create)
- `lib/providers/ad_provider.dart` (create)
- `test/services/ad_service_test.dart` (create)
- `android/app/src/main/AndroidManifest.xml` (modify - add AdMob app ID)

**What:**  
Implement complete AdMob integration:

**Ad Service:**
- Initialize AdMob: `MobileAds.instance.initialize()`
- Load Banner Ads: 50dp height, anchored bottom
- Load Interstitial Ads: Full screen, after conversion
- Check Ad Status: Respects "Remove Ads" IAP flag
- Handle Ad Events: onAdLoaded, onAdFailedToLoad, onAdOpened, onAdClosed

**Ad Provider:**
- State: `bannerAdLoaded`, `interstitialAdLoaded`, `adsRemoved`, `adFrequency`
- Methods: `loadBannerAd()`, `loadInterstitialAd()`, `showInterstitialAd()`, `disposeBannerAd()`, `checkAdRemovalStatus()`

**Ad Placement:**
- **Banner Ads:** Bottom of Home, History, Settings, Success, Error screens
- **Interstitial Ads:** After EVERY conversion (configurable via `app_constants.dart`)
- **No Ads During:** Conversion progress screen

**Configuration (Environment):**
```dart
// lib/constants/app_constants.dart
class AdConfig {
  static const int interstitialFrequency = 1; // Show after every X conversions
  static const bool testMode = true; // Use test ad units
  
  // Test Ad Units (switch to real in production)
  static const String bannerAdUnitId = testMode 
    ? 'ca-app-pub-3940256099942544/6300978111' // Test
    : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Real
    
  static const String interstitialAdUnitId = testMode
    ? 'ca-app-pub-3940256099942544/1033173712' // Test
    : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Real
}
```

**Testing:**
- Test ad loading (test mode only)
- Test ad display on each screen
- Test interstitial frequency logic
- Test "Remove Ads" IAP disables ads
- Test ad failure handling (graceful degradation)

---

### Step 15: In-App Purchase (Remove Ads)

**Files:**
- `lib/services/iap_service.dart` (create)
- `test/services/iap_service_test.dart` (create)

**What:**  
Implement Remove Ads IAP:

**IAP Service:**
- Product ID: `remove_ads_v1` (non-consumable)
- Price: $1.99
- Methods:
  - `initializeIAP()`: Connect to Play Store
  - `loadProducts()`: Fetch product details + price
  - `purchaseRemoveAds()`: Initiate purchase flow
  - `restorePurchases()`: For reinstalls
  - `checkPurchaseStatus()`: Returns true if purchased
  - `listenToPurchaseUpdates()`: Handle purchase callbacks

**Purchase Flow:**
1. User taps "Remove Ads & Unlock Pro" in Settings
2. Show loading dialog
3. Call `IapService.purchaseRemoveAds()`
4. Handle callbacks:
   - **Success:** Update `SettingsProvider.adsRemoved = true`, show success snackbar, hide all ads
   - **Cancelled:** Show "Purchase cancelled" snackbar
   - **Error:** Show "Purchase failed" with retry option
5. Persist purchase status in `SharedPreferences`

**Restore Purchases:**
- Add "Restore Purchases" link in Settings (under Remove Ads button)
- Useful for users who reinstalled app
- Validates with Play Store

**Testing:**
- Test purchase flow (sandbox mode)
- Test purchase restoration
- Test persistence (SharedPreferences)
- Test error handling (no connection, cancelled)
- Verify ads disappear after purchase

---

### Step 16: Final Integration & Polish

**Files:**
- `lib/app.dart` (update with routing)
- `lib/main.dart` (update with provider setup)
- `lib/utils/validation_utils.dart` (create)
- All screens (add navigation)

**What:**  
Final integration of all components:

**Routing Setup (no go_router for MVP - use Navigator 2.0):**
```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
  home: SplashScreen(),
  routes: {
    '/home': (context) => HomeScreen(),
    '/conversion-options': (context) => ConversionOptionsScreen(),
    '/converting': (context) => ConvertingScreen(),
    '/success': (context) => SuccessScreen(),
    '/error': (context) => ErrorScreen(),
    '/history': (context) => HistoryScreen(),
    '/settings': (context) => SettingsScreen(),
  },
)
```

**Provider Setup:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ConversionProvider()),
    ChangeNotifierProvider(create: (_) => HistoryProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => AdProvider()),
  ],
  child: MyApp(),
)
```

**Polish Items:**
- Add haptic feedback on button presses (`HapticFeedback.lightImpact()`)
- Add hero animations (Home → Conversion Options)
- Add page transitions (slide from right, 300ms)
- Add shimmer loading for conversion cards
- Add fade-in animations for screens (`flutter_animate`)
- Add error boundaries (catch widget build errors)
- Add null safety checks everywhere
- Add input validation utilities
- Add accessibility labels (semantic widgets)

**Validation Utils:**
```dart
class ValidationUtils {
  static String? validateOutputName(String name) {
    if (name.isEmpty) return 'Name cannot be empty';
    if (name.length > 50) return 'Name too long (max 50 chars)';
    if (RegExp(r'[/\\*?:|<>"]').hasMatch(name)) {
      return 'Invalid characters';
    }
    return null; // Valid
  }
  
  static bool isVideoFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp4', 'avi', 'mkv', 'mov', '3gp', 'flv', 'webm'].contains(ext);
  }
}
```

**Testing:**
- End-to-end flow testing (manual)
- Test all navigation paths
- Test back button handling
- Test error boundaries
- Test accessibility (TalkBack/VoiceOver)
- Test on multiple screen sizes
- Test on Android 8.0, 10, 13, 14

---

### Step 17: Performance Optimization & Error Handling

**Files:**
- All service files (add error handling)
- All provider files (add loading states)
- `lib/utils/logger.dart` (create)
- `android/app/proguard-rules.pro` (update)

**What:**  
Optimize performance and add robust error handling:

**Performance:**
- Enable ProGuard for release builds (shrink FFmpeg binaries)
- Optimize image assets (use WebP format)
- Lazy-load heavy widgets (conversion cards)
- Debounce search input (300ms)
- Cache file metadata (avoid re-reading)
- Dispose controllers/streams properly
- Use `const` constructors everywhere possible
- Profile with Flutter DevTools (check for jank)

**Error Handling:**
- Wrap all async operations in try-catch
- Show user-friendly error messages (no stack traces)
- Log technical errors to console
- Add error boundaries for widget trees
- Handle file system errors (no space, no permissions)
- Handle FFmpeg errors (invalid video, codec issues)
- Handle network errors (AdMob, IAP)
- Add timeout handling (FFmpeg max 10 minutes)

**Logger Utility:**
```dart
class Logger {
  static void info(String message) {
    if (kDebugMode) print('[INFO] $message');
  }
  
  static void error(String message, [dynamic error, StackTrace? stack]) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) print('Error: $error');
      if (stack != null) print('Stack: $stack');
    }
    // In production: send to Crashlytics
  }
}
```

**Testing:**
- Test error scenarios (no space, invalid video, cancelled)
- Test app size (target: <30MB)
- Profile frame rate (target: 60 FPS)
- Test memory usage (no leaks)
- Test battery usage (FFmpeg efficiency)

---

### Step 18: Testing Suite & Documentation

**Files:**
- `test/` directory (all test files)
- `test_driver/` directory (integration tests)
- `README.md` (create)
- `docs/ARCHITECTURE.md` (create)
- `docs/SETUP.md` (create)
- `docs/TESTING.md` (create)

**What:**  
Complete testing suite and documentation:

**Testing Coverage:**
- **Unit Tests:** 80%+ coverage
  - All services (FFmpeg, Storage, Database, Permissions, IAP, Ads)
  - All providers (Conversion, History, Settings, Ad)
  - All utilities (File, Format, Validation, Logger)
- **Widget Tests:** 60%+ coverage
  - All screens (Home, ConversionOptions, Converting, Success, Error, History, Settings)
  - All reusable widgets (Buttons, Cards, Selectors, Progress)
- **Integration Tests:** Critical flows
  - Full conversion flow (video → MP3)
  - History management
  - Settings persistence
  - Ad display logic
  - IAP purchase flow

**Documentation:**

**README.md:**
```markdown
# MP3 Extract - Video to MP3 Converter

Fast, private, offline video to MP3 converter for Android.

## Features
- Convert any video to MP3 (128/192/320 kbps)
- 100% offline - no internet required
- No account, no login, no cloud
- Conversion history with search
- Dark/Light mode
- Remove ads for $1.99

## Tech Stack
- Flutter 3.24+
- FFmpeg Kit
- Provider (state management)
- SQLite (local database)
- AdMob + IAP

## Setup
See [SETUP.md](docs/SETUP.md)

## Architecture
See [ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Testing
See [TESTING.md](docs/TESTING.md)
```

**ARCHITECTURE.md:** Document MVVM pattern, data flow, service layer, provider responsibilities.

**SETUP.md:** Step-by-step setup instructions (Flutter SDK, Android Studio, dependencies, AdMob keys, IAP setup).

**TESTING.md:** How to run tests, coverage reports, manual testing checklist.

**Testing:**
- Run `flutter test --coverage` (target: 80%+ overall)
- Run integration tests on real device
- Manual testing checklist (all scenarios)
- Performance profiling (DevTools)

---

### Step 19: Build Configuration & Release Preparation

**Files:**
- `android/app/build.gradle` (update for release)
- `android/key.properties` (create - gitignored)
- `android/app/proguard-rules.pro` (finalize)
- `android/app/src/main/res/` (app icons, splash)
- `.gitignore` (update)
- `pubspec.yaml` (finalize version)

**What:**  
Prepare for production release:

**Build Configuration:**
```gradle
// android/app/build.gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.mp3extract.app" // CHANGE THIS
        minSdkVersion 26
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

**ProGuard Rules (FFmpeg specific):**
```proguard
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.** { *; }
```

**App Icons:**
- Generate adaptive icons (1024x1024 source)
- Foreground: App logo (gradient blue, music note)
- Background: Solid color (#2563EB)
- Use `flutter_launcher_icons` package

**Splash Screen:**
- Use `flutter_native_splash` package
- Background: #0F172A (dark)
- Logo: 200x200dp centered
- Text: "MP3 Extract" below

**Version Management:**
```yaml
# pubspec.yaml
version: 1.0.0+1 # major.minor.patch+build
```

**Environment Variables:**
```dart
// lib/config/env.dart (gitignored)
class Env {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const String admobAppId = String.fromEnvironment('ADMOB_APP_ID');
  static const String bannerAdUnitId = String.fromEnvironment('BANNER_AD_UNIT_ID');
  static const String interstitialAdUnitId = String.fromEnvironment('INTERSTITIAL_AD_UNIT_ID');
}
```

**Testing:**
- Build release APK: `flutter build apk --release`
- Build release AAB: `flutter build appbundle --release`
- Test on real device (release mode)
- Verify ProGuard shrinking (check APK size)
- Test AdMob with REAL ad units (not test mode)
- Test IAP with sandbox account

---

### Step 20: Final QA & Launch Preparation

**Files:**
- `docs/LAUNCH_CHECKLIST.md` (create)
- Play Store assets (screenshots, feature graphic, video)
- Privacy policy HTML page (host on GitHub Pages or website)

**What:**  
Final quality assurance and launch prep:

**QA Testing Checklist:**
- [ ] Test on Android 8.0 (API 26)
- [ ] Test on Android 10 (API 29) - SAF permissions
- [ ] Test on Android 13 (API 33) - new permissions
- [ ] Test on Android 14 (API 34) - latest
- [ ] Test on 3 screen sizes (small 5", medium 6", large 7")
- [ ] Test with 5-minute video (various formats: MP4, AVI, MKV)
- [ ] Test with 30-minute video (warn user)
- [ ] Test with 1-hour video (ensure no timeout)
- [ ] Test airplane mode (offline functionality)
- [ ] Test low storage scenario (<100MB free)
- [ ] Test app kill during conversion (background task)
- [ ] Test dark/light mode switching
- [ ] Test AdMob banner/interstitial display
- [ ] Test IAP purchase flow (real money - refund after)
- [ ] Test IAP restoration after reinstall
- [ ] Test share functionality (WhatsApp, Gmail, etc.)
- [ ] Test file deletion (history)
- [ ] Test search (history)
- [ ] Test filters (today, week, high quality)
- [ ] Test settings persistence
- [ ] Test conversion cancellation
- [ ] Test error recovery
- [ ] Test TalkBack accessibility
- [ ] Test with screen reader
- [ ] Profile performance (60 FPS target)
- [ ] Check for memory leaks (DevTools)
- [ ] Verify no crashes (Crashlytics - if integrated)

**Play Store Assets:**
1. **App Icon:** 512x512 PNG (high-res, transparent background)
2. **Feature Graphic:** 1024x500 PNG (hero banner)
3. **Screenshots:** 5-8 phone screenshots + 2-4 tablet screenshots
   - Home screen (show recent conversions)
   - Quality selection (highlight options)
   - Conversion progress (show speed)
   - Success screen (show share)
   - Settings (highlight Remove Ads)
   - History (show filters)
4. **App Video:** 30-second demo (optional but recommended)
5. **Short Description:** 80 chars
   ```
   Convert videos to MP3 offline. Fast, free, no account needed.
   ```
6. **Full Description:** See research doc (ASO optimized)
7. **Privacy Policy:** Must host on public URL
   - Covers: Data collection (none), permissions, ads, IAP, third-party services (AdMob, Play Billing)

**Content Rating:**
- Complete questionnaire (ESRB/PEGI)
- Expected rating: Everyone (no inappropriate content)

**App Category:**
- Primary: Music & Audio
- Tags: converter, audio, mp3, video, offline, utility

**Pricing & Distribution:**
- Free (with ads + IAP)
- Countries: All (or target specific regions)

**Release Track:**
1. **Internal Testing:** (10-100 testers, quick feedback)
2. **Closed Testing:** (Alpha/Beta, 100-1000 testers)
3. **Open Testing:** (Public beta, opt-in)
4. **Production:** (Full release)

**Testing:**
- Complete all QA checklist items
- Get feedback from 5-10 beta testers
- Fix any critical bugs found
- Verify all Play Store assets look correct in preview
- Test privacy policy link (publicly accessible)

---

## Post-Launch Plan (Week 1)

### Monitoring
- [ ] Check crash rate hourly (target: <0.5%)
- [ ] Monitor conversion success rate (target: >95%)
- [ ] Track DAU/MAU growth
- [ ] Monitor ad fill rate (AdMob)
- [ ] Track IAP conversion rate (target: >2%)
- [ ] Review user feedback (daily)
- [ ] Respond to reviews within 24 hours

### Metrics to Track
- **Day 1 Retention:** Target >25%
- **Day 7 Retention:** Target >12%
- **Day 30 Retention:** Target >6%
- **Average Rating:** Target >4.5★
- **Conversions per User:** Target >3
- **Ad Revenue per DAU:** Target $0.05-0.10

### Optimization Opportunities
- A/B test screenshots (improve conversion)
- Adjust ad frequency if users complain
- Add requested features (batch conversion in Phase 2)
- Localize to top 3 languages (Spanish, Portuguese, Hindi)
- Expand to iOS (Flutter advantage)

---

## Phase 2 Features (Future Roadmap)

### Batch Conversion
- Select multiple videos at once
- Queue management (pause/resume/reorder)
- Parallel processing (device-dependent)
- Global settings (apply same quality to all)
- Batch completion notification

### Advanced Features
- Trim video before conversion
- Custom bitrate selection
- Audio format options (AAC, FLAC, WAV)
- Metadata editor (artist, album, cover art)
- Audio effects (normalize, fade in/out)
- Cloud backup integration (Google Drive, Dropbox)
- Ringtone maker (30-second clips)

### Monetization Enhancements
- Pro subscription ($2.99/month or $19.99/year)
  - Batch conversion
  - Advanced features
  - Priority support
- Referral program (share app, earn credits)
- Branded themes (customization)

### Platform Expansion
- iOS version (Flutter reuse)
- Desktop version (Windows, macOS, Linux)
- Chrome extension (web-based converter)

---

## Summary

This is a **COMPLEX** feature broken into **20 testable steps**. Each step builds upon the previous, ensuring steady progress toward a production-ready app.

**Key Success Factors:**
1. ✅ **Follow tech stack exactly** (no deviations from Provider + specified packages)
2. ✅ **Match design specs precisely** (colors, typography, spacing, components)
3. ✅ **Prioritize UX** (60-second first conversion, no bottom nav, clear flows)
4. ✅ **Fair monetization** (non-intrusive ads, reasonable IAP pricing)
5. ✅ **Robust error handling** (graceful failures, clear messages, automatic cleanup)
6. ✅ **Comprehensive testing** (80% unit, 60% widget, integration flows)
7. ✅ **Performance** (60 FPS, fast conversions, small APK size)
8. ✅ **Privacy-first** (offline, no account, no tracking beyond AdMob/Analytics)

**Estimated Timeline:**
- **Development:** 4-6 weeks (solo developer, part-time)
- **Testing:** 1-2 weeks (QA + beta testing)
- **Launch Prep:** 1 week (Play Store assets, policy, submission)
- **Total:** 6-9 weeks to production

**Final APK Size Target:** <30MB (compressed)  
**First Conversion Time:** <60 seconds  
**Target Rating:** >4.5★  
**Target Revenue:** $300-500/month (conservative first 3 months)

Ready to start implementation! 🚀
