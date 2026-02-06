# Testing Guide

## Quick Start

```bash
# Run all tests
flutter test

# Run with verbose output
flutter test --reporter expanded

# Run with coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Structure

```
test/
├── models/
│   └── conversion_task_test.dart      # ConversionTask + ConversionStatus
├── providers/
│   ├── conversion_provider_test.dart  # ConversionProvider unit tests
│   ├── history_provider_test.dart     # HistoryProvider with mocked DB
│   └── settings_provider_test.dart    # SettingsProvider with mock prefs
├── services/
│   └── database_service_test.dart     # AudioFile, AudioQuality models
└── utils/
    ├── debouncer_test.dart            # Debouncer with fake_async
    ├── file_utils_test.dart           # FileUtils (extension check, naming)
    ├── format_utils_test.dart         # FormatUtils (size, duration, date)
    └── validation_utils_test.dart     # ValidationUtils (file name rules)
```

## Test Coverage by Area

| Area | Tests | Coverage |
|---|---|---|
| Models (AudioFile, AudioQuality, ConversionTask) | 19 | ~95% |
| Utils (Format, File, Validation, Debouncer) | 30 | ~90% |
| Providers (Settings, History, Conversion) | 28 | ~80% |
| Services (Database) | 11 | ~70% |
| **Total** | **88** | **~85%** |

## Mocking Strategy

- **`mocktail`** — used for service mocking (no codegen needed)
- **`SharedPreferences.setMockInitialValues`** — used for Settings tests
- **`fake_async`** — used for Debouncer timer tests

## Running Specific Tests

```bash
# Single file
flutter test test/utils/format_utils_test.dart

# By name pattern
flutter test --name "fileSize"

# Only models
flutter test test/models/
```

## Manual Testing Checklist

### Conversion Flow
- [ ] Select video (MP4, MKV, AVI, MOV)
- [ ] Edit output name
- [ ] Change quality (128 → 192 → 320)
- [ ] Tap CONVERT NOW → see progress ring
- [ ] Wait for completion → success screen
- [ ] Verify MP3 plays in file manager
- [ ] Share MP3 via WhatsApp / Gmail
- [ ] Delete MP3 from success screen

### Error Scenarios
- [ ] Cancel conversion mid-progress
- [ ] Select corrupted video file
- [ ] Fill disk space → verify "Not enough storage" error
- [ ] Kill app during conversion → reopen → verify clean state

### History
- [ ] Search by file name
- [ ] Filter by Today / Last 7 Days / High Quality
- [ ] Delete single conversion
- [ ] Clear all history
- [ ] Share from history overflow menu

### Settings
- [ ] Toggle dark/light mode
- [ ] Change default quality → verify it's applied on next conversion
- [ ] Toggle normalize volume → verify audio output differs
- [ ] Toggle auto-delete → verify source video is deleted
- [ ] Clear cache → verify snackbar
- [ ] Tap Remove Ads → verify IAP dialog (sandbox)

### Ads
- [ ] Banner appears on Home, Options, Success, Error, History
- [ ] Banner does NOT appear on Converting screen
- [ ] Interstitial shows after successful conversion
- [ ] After purchasing Remove Ads → no banners, no interstitials

### Edge Cases
- [ ] Very long video (>1 hour) — timeout at 10 min
- [ ] Very short video (<5 seconds)
- [ ] Video with no audio track
- [ ] App in background during conversion
- [ ] Rotate device (locked to portrait — should stay)
- [ ] Android 8 (API 26) — storage permission prompt
- [ ] Android 14 (API 34) — scoped storage
