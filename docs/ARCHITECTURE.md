# Architecture

AudioPeel follows **MVVM + Repository** with a clean three-layer separation.

## Layer Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  screens/          widgets/common/                       │
│  (8 screens)       (8 reusable widgets)                  │
│                                                          │
│  Reads state via context.watch<Provider>()               │
│  Dispatches actions via context.read<Provider>().method() │
├─────────────────────────────────────────────────────────┤
│                    BUSINESS LOGIC LAYER                   │
│  providers/                                              │
│  ┌──────────────────┐  ┌──────────────────┐              │
│  │ ConversionProvider│  │ HistoryProvider   │              │
│  │ SettingsProvider  │  │ AdProvider        │              │
│  └──────────────────┘  └──────────────────┘              │
│                                                          │
│  Extends ChangeNotifier                                  │
│  Orchestrates services, manages UI state                 │
├─────────────────────────────────────────────────────────┤
│                    DATA / SERVICE LAYER                   │
│  services/                         models/               │
│  ┌─────────────────┐  ┌───────────────────┐              │
│  │ FFmpegService    │  │ AudioFile         │              │
│  │ DatabaseService  │  │ AudioQuality      │              │
│  │ StorageService   │  │ ConversionTask    │              │
│  │ PermissionService│  └───────────────────┘              │
│  │ IapService       │                                    │
│  └─────────────────┘                                     │
└─────────────────────────────────────────────────────────┘
```

## Data Flow: Video → MP3

```
User taps "SELECT VIDEO"
  → ConversionProvider.selectVideo()
    → FilePicker → selects file
    → FFmpegService.getVideoMetadata() → durationMs, sizeBytes
    → notifyListeners() → UI updates

User taps "CONVERT NOW"
  → ConversionProvider.startConversion()
    → StorageService.hasEnoughSpace() → check disk
    → StorageService.uniqueOutputPath() → generate path
    → FFmpegService.convertVideoToMp3()
      → onProgress callback → provider.notifyListeners() → ring updates
      → timeout Timer (10 min max)
    → On success:
      → DatabaseService.insertConversion() → persist history
      → StorageService.deleteFile() (if autoDelete enabled)
    → On failure:
      → StorageService.deleteFile() → cleanup partial output
    → notifyListeners() → screen navigates to Success/Error
```

## Provider Responsibilities

| Provider | Owns | Depends On |
|---|---|---|
| `ConversionProvider` | Video selection, conversion lifecycle, progress | FFmpegService, StorageService, DatabaseService |
| `HistoryProvider` | Conversion list, filters, search | DatabaseService |
| `SettingsProvider` | Dark mode, quality, normalise, auto-delete, ads-removed | SharedPreferences |
| `AdProvider` | Banner creation, interstitial load/show, frequency gating | google_mobile_ads |
| `IapService` | Purchase flow, restore, product details | in_app_purchase |

## Navigation Map

```
SplashScreen (1.5s, auto)
  └→ HomeScreen
      ├→ ConversionOptionsScreen
      │    └→ ConvertingScreen
      │         ├→ ConversionSuccessScreen
      │         └→ ConversionErrorScreen
      ├→ HistoryScreen
      └→ SettingsScreen
```

No bottom navigation bar. All navigation is push/pop via `Navigator`.

## Error Handling Strategy

1. **Services** — throw or return error results (never crash)
2. **Providers** — try-catch around all async calls, update state + notify
3. **Screens** — react to provider state (loading/error/success)
4. **ErrorBoundary widget** — catches build-phase errors in subtrees
5. **FFmpeg timeout** — 10-minute max, auto-cancel via `Timer`
6. **Disk space** — checked before every conversion (50 MB minimum)
7. **User-friendly messages** — raw FFmpeg logs mapped to plain English

## Constants Strategy

All magic numbers live in `lib/constants/`:

- `app_colors.dart` — colour palette
- `app_strings.dart` — all UI text
- `app_constants.dart` — sizes, durations, ad IDs, pref keys
- `app_theme.dart` — Material 3 ThemeData (light + dark)

## Testing Strategy

- **Unit tests** — models, utils, providers (with mocked services)
- **Widget tests** — planned for screens (Step 18+)
- **Integration tests** — planned for full conversion flow (Step 18+)
- **Target** — 80%+ unit coverage, 60%+ widget coverage
