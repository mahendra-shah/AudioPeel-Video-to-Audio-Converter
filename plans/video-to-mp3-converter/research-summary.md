# Video to MP3 Converter - Research Summary

**Date:** 6 February 2026  
**Project:** AudioPeel (Video to MP3 Converter)  
**Platform:** Flutter (Android-first)

---

## 1. MARKET VALIDATION ✅

### Market Size & Growth
- **2024 Market Size:** USD $2 Billion
- **2032 Projection:** USD $4.23 Billion
- **CAGR:** 9.8% growth rate
- **Conclusion:** Proven, evergreen utility app market

### Competition Analysis
| App | Downloads | Rating | Key Weakness |
|-----|-----------|--------|--------------|
| Video to MP3 Converter | 5M+ | 4.6★ | Too many ads |
| Video MP3 Converter | 10M+ | 4.5★ | Slow conversion |
| MP3 Video Converter | 1M+ | 4.4★ | Complex UI |

### Our Competitive Advantage
1. **Privacy-First:** No login, no cloud, no account
2. **Offline-First:** Works without internet
3. **Simple UX:** 60-second first conversion
4. **Fair Monetization:** Non-intrusive ads + optional IAP
5. **No Bottom Navigation:** Simplified single-flow UI

---

## 2. REVENUE MODEL

### Monetization Strategy
- **Interstitial Ads:** After EVERY conversion (configurable via env)
- **Banner Ads:** Bottom of screen (persistent, except during conversion)
- **Remove Ads IAP:** $1.99 one-time purchase
- **Ad Network:** Google AdMob

### Revenue Projections
| Scenario | Monthly Downloads | Active Users | IAP Conv. | Monthly Revenue |
|----------|-------------------|--------------|-----------|-----------------|
| Conservative | 10,000 | 600 | 2% | $300-400 |
| Moderate | 50,000 | 5,000 | 4% | $4,500-5,500 |

---

## 3. DESIGN SYSTEM

### Screens (9 Total - 18 with Dark/Light Modes)

#### Phase 1 Screens (MVP)
1. **Home Screen** - Single action screen with recent conversions
2. **Conversion Options** - Video preview + quality selection + output name
3. **Conversion Progress** - Circular progress with cancel option
4. **Success Screen** - Preview, share, convert another
5. **Settings Screen** - Quality defaults, theme, storage, Remove Ads
6. **Empty State** - First-time user onboarding
7. **Error State** - Conversion failure with retry option
8. **History Screen** - Filterable conversion history (All/Today/Last 7 Days/High Quality)

#### Phase 2 Screens (Future)
9. **Batch Conversion** - Multiple file processing (deferred)

### Design System Specifications

#### Color Palette
```dart
// Primary
const primaryBlue = Color(0xFF2563EB);
const success = Color(0xFF10B981);
const error = Color(0xFFEF4444);
const warning = Color(0xFFF59E0B);

// Light Mode
const surfaceLight = Color(0xFFFFFFFF);
const cardLight = Color(0xFFF8FAFC);
const textPrimaryLight = Color(0xFF0F172A);
const textSecondaryLight = Color(0xFF64748B);

// Dark Mode
const surfaceDark = Color(0xFF0F172A);
const cardDark = Color(0xFF1E293B);
const textPrimaryDark = Color(0xFFF8FAFC);
const textSecondaryDark = Color(0xFF94A3B8);
```

#### Typography
- **Display:** Poppins Bold 24sp
- **Screen Titles:** Poppins SemiBold 20sp
- **Section Headers:** Poppins Medium 16sp
- **Body Text:** Inter Regular 14sp
- **Captions:** Inter Regular 12sp
- **Button Text:** Inter SemiBold 15sp (UPPERCASE)

#### Spacing System
- Section gaps: 24dp
- Element gaps: 16dp
- Small item gaps: 8dp
- Card padding: 16dp
- Screen padding: 16dp
- Tiny gaps: 4dp

#### Components
- **Primary Button:** 56dp height, 16dp radius, full width
- **Card:** 16dp radius, 16dp padding, elevation 2
- **List Item:** 72dp height, 12dp radius
- **Input Field:** 52dp height, 12dp radius
- **Quality Toggle:** 48dp height, 12dp radius, equal width distribution

### Navigation Architecture
**SIMPLIFIED - NO BOTTOM NAVIGATION**
- Home screen is default entry point
- Settings icon in top-right corner (all screens)
- "See All" link from Home → History Screen
- Standard back button navigation
- System navigation gesture support

**Rationale:** Maximizes space for conversions and ads, simplifies UX

---

## 4. TECHNICAL ARCHITECTURE

### Tech Stack (Mandated - NO Deviations)

#### Core
- **Flutter SDK:** 3.24+ (latest stable)
- **Dart:** Latest stable
- **Material Design:** Material 3 (Material You)
- **Theme:** Dark mode first, light mode secondary

#### State Management
- **ONLY:** `provider` with `ChangeNotifier`
- **PROHIBITED:** Riverpod, Bloc, GetX, MobX

#### Required Packages (Verified on pub.dev)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.2
  
  # Media Processing
  ffmpeg_kit_flutter: ^6.0.3  # Native FFmpeg bindings
  
  # Permissions
  permission_handler: ^11.3.1
  
  # File Operations
  path_provider: ^2.1.4
  file_picker: ^8.0.5
  
  # Ads & IAP
  google_mobile_ads: ^5.1.0
  in_app_purchase: ^3.2.0
  
  # Database
  sqflite: ^2.3.3+1  # Local conversion history
  
  # UI Utilities
  shimmer: ^3.0.0
  flutter_animate: ^4.5.0
  
  # Utilities
  intl: ^0.19.0
  shared_preferences: ^2.3.2
```

### Architecture Pattern: MVVM + Repository Pattern

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + Theme + Routes
├── constants/
│   ├── app_colors.dart         # Color system
│   ├── app_strings.dart        # All text strings
│   ├── app_constants.dart      # Magic numbers, config
│   └── app_theme.dart          # Theme data
├── models/
│   ├── conversion_task.dart    # Conversion job model
│   ├── audio_file.dart         # MP3 file metadata
│   └── audio_quality.dart      # Quality enum (128/192/320)
├── providers/                   # ChangeNotifier ViewModels
│   ├── conversion_provider.dart
│   ├── history_provider.dart
│   ├── settings_provider.dart
│   └── ad_provider.dart
├── services/                    # Business logic
│   ├── ffmpeg_service.dart     # Video to MP3 conversion
│   ├── permission_service.dart # Storage permissions
│   ├── storage_service.dart    # File I/O operations
│   ├── database_service.dart   # SQLite operations
│   ├── ad_service.dart         # AdMob integration
│   └── iap_service.dart        # In-app purchases
├── screens/                     # UI (dumb widgets)
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── conversion_options_screen.dart
│   ├── converting_screen.dart
│   ├── success_screen.dart
│   ├── settings_screen.dart
│   ├── empty_state_screen.dart
│   ├── error_screen.dart
│   └── history_screen.dart
├── widgets/                     # Reusable components
│   ├── common/
│   │   ├── primary_button.dart
│   │   ├── secondary_button.dart
│   │   ├── quality_selector.dart
│   │   ├── progress_ring.dart
│   │   ├── conversion_card.dart
│   │   └── empty_state.dart
│   └── audio/
│       ├── audio_preview_player.dart
│       └── waveform_visualizer.dart
└── utils/
    ├── file_utils.dart          # File size, extension helpers
    ├── format_utils.dart        # Duration, date formatting
    └── validation_utils.dart    # Input validation
```

---

## 5. CORE FEATURES & DECISIONS

### Phase 1 Features (MVP - Production Ready)

#### 1. Video Selection & Import
- Use `file_picker` package (no permissions needed on Android 10+)
- Support all video formats: MP4, AVI, MKV, MOV, 3GP, FLV, WebM
- **Any video length allowed** - no restrictions
- Show estimated conversion time BEFORE conversion starts
- Warn if video > 30 minutes (but allow conversion)

#### 2. Quality Selection
- **3 Options:** 128 kbps, 192 kbps, 320 kbps
- **Default:** 192 kbps (stored in settings)
- **Display:** Radio buttons / Toggle buttons with equal width

#### 3. Output Naming
- **Default:** `{original_filename}_audio.mp3`
- **Editable:** User can change before conversion
- **Validation:** No special characters, max 50 chars

#### 4. Conversion Process
- **Engine:** FFmpeg Kit Flutter (native speed)
- **Progress:** Real-time percentage updates
- **Cancellable:** User can cancel anytime
- **Background:** Uses WorkManager (survives app close)
- **Error Handling:** Log errors, delete partial files, show reason

#### 5. Conversion History
- **Storage:** SQLite database
- **Capacity:** Keep ALL conversions until user deletes
- **Display:** 3-4 recent on Home, full list in History screen
- **Filters:** All / Today / Last 7 Days / High Quality
- **Search:** By filename
- **Actions:** Share, Delete, Re-convert

#### 6. Audio Preview
- **Basic playback only** (play/pause/seek)
- **Waveform visualization** (optional - can use package)
- **Duration display**

#### 7. File Management
- **Default Location:** `Music/MP3Converter/`
- **User Choice:** Can select custom folder via SAF
- **Auto-delete Source:** Optional setting (default: OFF)

#### 8. Settings
- Default audio quality (128/192/320)
- Dark/Light mode toggle
- Auto-delete source video after conversion
- Output folder selection
- Clear cache
- Remove Ads IAP
- App version
- Privacy policy link

#### 9. Monetization
- **Interstitial Ad:** After EVERY conversion (configurable)
- **Banner Ad:** Bottom of all screens except conversion progress
- **Remove Ads IAP:** $1.99 one-time
- **AdMob Test Mode:** For development/testing
- **Ad Frequency Config:** Via environment variable

#### 10. Performance
- **Conversion Speed:** Native FFmpeg (8-15 seconds for 5-min 720p video)
- **UI:** 60 FPS target
- **First Conversion:** < 60 seconds from app open

### Phase 2 Features (Future Enhancements)
- Batch conversion (multiple files at once)
- Parallel processing based on device capability:
  - **Low-end devices:** Sequential (1 at a time)
  - **Mid-range devices:** 2-3 parallel instances
  - **High-end devices:** 4-5 parallel instances
- Advanced audio settings (bitrate, sample rate, channels)
- Trim video before conversion
- Metadata editor (artist, album, cover art)

---

## 6. PERMISSIONS STRATEGY

### Android 13+ Approach (No Traditional Permissions)
```dart
// For picking videos - NO permissions needed
final result = await FilePicker.platform.pickFiles(
  type: FileType.video,
  allowMultiple: false,
);

// For saving MP3 - Uses Storage Access Framework
// NO permissions needed on Android 10+
final directory = await getExternalStorageDirectory();
final outputPath = '${directory!.path}/Music/MP3Converter/';
```

### Legacy Android (8.0-9.0)
```dart
// Only if targetSdk < 29
if (Platform.isAndroid && androidVersion < 10) {
  await Permission.storage.request();
}
```

---

## 7. UI/UX GUIDELINES

### 60-Second First Conversion Principle
```
[App Launch] → [Home Screen] → [Select Video] → [Quality Select] → [Convert] → [Success]
     1s              2s              10s              5s              30s          2s
```

**Total:** ~50 seconds (leaves 10s buffer)

### Touch Target Standards
- **Minimum:** 48x48dp (Material Design)
- **Recommended:** 56dp for primary actions
- **Spacing:** 8dp minimum between interactive elements

### Thumb Zone Design
- Primary actions in bottom 2/3 of screen
- One-handed operation optimized
- FAB placement: Bottom-right (removed - no bottom nav)

### Loading States
- Shimmer effect for list items
- Circular progress for conversions
- Skeleton screens for heavy screens

### Error States
- Clear error messages (no technical jargon)
- Actionable buttons (Retry, Select Another)
- Log technical details to console
- Delete partial files automatically

### Empty States
- Friendly illustration
- Clear call-to-action
- Benefit-oriented messaging

---

## 8. TESTING STRATEGY

### Unit Tests
- All services (FFmpeg, Storage, Database, Permissions)
- All providers (Conversion, History, Settings)
- All utilities (File, Format, Validation)
- **Target Coverage:** 80%+

### Widget Tests
- All screens
- All reusable widgets
- Navigation flows
- User interactions
- **Target Coverage:** 60%+

### Integration Tests
- End-to-end conversion flow
- Ad display logic
- IAP purchase flow
- Permission handling

### Manual Testing Checklist
- [ ] Test on Android 8.0, 10, 13, 14
- [ ] Test on 3 screen sizes (small/medium/large)
- [ ] Test with 5-minute video
- [ ] Test with 30-minute video
- [ ] Test with 1-hour video
- [ ] Test airplane mode (offline)
- [ ] Test low storage scenario
- [ ] Test app kill during conversion
- [ ] Test dark/light mode switching
- [ ] Test ad display (test mode)
- [ ] Test IAP purchase (sandbox)

---

## 9. APP STORE OPTIMIZATION (ASO)

### App Name
**Primary:** "AudioPeel - Video to MP3 Converter"  
**Short:** "AudioPeel"

### Keywords
- video to mp3
- mp3 converter
- audio extractor
- video converter
- extract audio
- mp3 from video
- offline converter
- ringtone maker

### Description Structure
```
[Short] Convert videos to MP3 offline. Fast, free, no account needed.

[Long]
Extract audio from any video in seconds. No internet required.

✅ KEY FEATURES:
• Pick any video from your device
• Choose quality: 128kbps, 192kbps, or 320kbps
• Convert offline - no internet needed
• Save MP3 to your device
• No account, no login, no cloud

🚀 WHY USERS LOVE US:
• Fastest conversion speed
• Simple 3-tap process
• No quality loss
• 100% private

Download now and convert your first video in under 60 seconds!
```

### Screenshots (5-8 Required)
1. Home screen (show recent conversions)
2. Quality selection (highlight 3 options)
3. Conversion progress (show speed)
4. Success screen (show share option)
5. Settings (highlight "Remove Ads")
6. History screen (show filters)
7. Empty state (show simplicity)
8. (Optional) Comparison chart vs competitors

### Feature Graphic
- Clean, modern design
- App icon + tagline
- Key benefit: "Extract Audio in Seconds"
- "Offline • Free • No Account" badges

---

## 10. LAUNCH CHECKLIST

### Pre-Launch
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots (5-8, phone + tablet)
- [ ] Privacy policy page (hosted)
- [ ] Content rating questionnaire
- [ ] Test on 5+ devices
- [ ] Crash reporting setup (Firebase Crashlytics)
- [ ] Analytics setup (Firebase Analytics)
- [ ] AdMob account + ad units
- [ ] Google Play Console setup
- [ ] APK/AAB build (release mode)
- [ ] ProGuard rules configured

### Post-Launch (Week 1)
- [ ] Monitor crash rate (target: <0.5%)
- [ ] Monitor conversion rate
- [ ] Respond to reviews (within 24h)
- [ ] Track key metrics (DAU, retention)
- [ ] A/B test screenshots
- [ ] Adjust ad frequency if needed

### Success Metrics
| Metric | Target |
|--------|--------|
| Day 1 Retention | >25% |
| Day 7 Retention | >12% |
| Day 30 Retention | >6% |
| Average Rating | >4.5★ |
| Crash Rate | <0.5% |
| Remove Ads Conv. | >2% |
| Avg. Conversions/User | >3 |

---

## 11. DESIGN INCONSISTENCIES FOUND

Based on design file analysis and system instructions:

### ✅ Consistent Elements
1. Color palette matches spec (#2563EB primary)
2. Typography hierarchy correct
3. Component sizing (buttons, cards) matches
4. Spacing system followed
5. Dark/light mode variants provided

### ⚠️ Clarifications Needed
1. **Bottom Navigation:** Design shows it, but decision is to REMOVE IT
   - **Action:** Need to redesign Home, History, Settings without bottom nav
   - **Impact:** More space for content and ads

2. **Batch Conversion Screens:** Designed but deferred to Phase 2
   - **Action:** Skip implementation in MVP
   - **Impact:** Faster time to market

3. **Ad Placement:** Design shows "ADVERTISEMENT" placeholder
   - **Action:** Need exact banner ad dimensions (50dp height confirmed)
   - **Impact:** None - standard AdMob banner

4. **FAB Button:** Design shows floating action button
   - **Action:** Remove if no bottom nav (redundant)
   - **Impact:** Cleaner UI

5. **History Screen Filters:** Design shows tabs (All/Today/Last 7/High Quality)
   - **Action:** Confirm filter implementation details
   - **Impact:** None - straightforward

---

## 12. CRITICAL DECISIONS SUMMARY

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Platform Priority** | Android-first | 95% of utility app market |
| **Min Android Version** | API 26 (Android 8.0+) | 99%+ device coverage |
| **State Management** | Provider only | Mandated, simple, sufficient |
| **FFmpeg Package** | ffmpeg_kit_flutter | Most mature, actively maintained |
| **Navigation** | No bottom nav | Maximizes space, simplifies UX |
| **Batch Processing** | Phase 2 | Complexity vs MVP speed tradeoff |
| **Parallel Conversions** | Sequential only (MVP) | Simpler, device-agnostic |
| **Ad Frequency** | Every conversion | Maximizes revenue, configurable |
| **IAP Strategy** | One-time $1.99 | No subscription friction |
| **History Storage** | SQLite (unlimited) | User control, privacy |
| **Video Length** | No limit | User freedom, show warnings only |
| **Default Quality** | 192 kbps | Balance of size/quality |

---

## 13. OPEN QUESTIONS FOR PLANNING

### Answered ✅
1. ✅ Design screen mapping (9 screens, 18 with modes)
2. ✅ Scope: Full feature set (Phase 1)
3. ✅ Batch processing: Phase 2
4. ✅ Bottom navigation: Remove completely
5. ✅ Ad frequency: Every conversion
6. ✅ History display: 3-4 on home, fade effect
7. ✅ Parallel processing: Sequential for MVP
8. ✅ Video length limits: None (warn only)
9. ✅ Error handling: Log + delete partial files

### Ready for Implementation Planning 🚀
All major decisions finalized. Ready to break down into implementation steps.

---

**Next Step:** Generate detailed implementation plan with commit-by-commit breakdown.
