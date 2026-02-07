# Voca:Video To Audio Converter

Fast, private, offline video-to-MP3 converter for Android.

## Features

- **Convert any video to MP3** — supports MP4, MKV, AVI, MOV, WMV, FLV, WebM, 3GP, TS, M4V
- **Three quality levels** — 128 kbps (Standard), 192 kbps (High), 320 kbps (Maximum)
- **100% offline** — no internet required, no uploads, no cloud
- **No account needed** — zero sign-up, zero login
- **Conversion history** — search, filter by date/quality, share/delete
- **Dark & Light mode** — dark mode by default
- **Volume normalisation** — optional `loudnorm` filter
- **Auto-delete original** — optionally removes the source video after conversion
- **Remove Ads** — one-time $1.99 in-app purchase

## Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter 3.24+ / Dart 3.10 |
| State Management | Provider + ChangeNotifier |
| Media Processing | FFmpeg Kit 6.0.3 |
| Database | SQLite via sqflite |
| Preferences | SharedPreferences |
| Ads | Google Mobile Ads (AdMob) |
| In-App Purchase | in_app_purchase |
| Typography | Google Fonts (Poppins + Inter) |

## Architecture

MVVM + Repository pattern with three layers:

```
┌──────────────┐
│   Screens    │  ← UI layer (StatelessWidget / StatefulWidget)
├──────────────┤
│  Providers   │  ← Business logic (ChangeNotifier)
├──────────────┤
│  Services    │  ← Data layer (FFmpeg, SQLite, Storage, IAP, Ads)
└──────────────┘
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full details.

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── app.dart                   # MaterialApp + theming
├── constants/                 # Colors, strings, sizing, theme
├── models/                    # AudioFile, AudioQuality, ConversionTask
├── services/                  # FFmpeg, Database, Storage, Permission, IAP
├── providers/                 # Conversion, History, Settings, Ad
├── screens/                   # Splash, Home, Options, Converting, Success, Error, History, Settings
├── widgets/common/            # Buttons, cards, progress ring, banner ad, error boundary
└── utils/                     # Format, File, Validation, Logger, Debouncer
```

## Setup

```bash
# Clone
git clone <repo-url>
cd mp3_extract

# Install dependencies
flutter pub get

# Run
flutter run
```

See [docs/SETUP.md](docs/SETUP.md) for detailed environment setup.

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run a specific test file
flutter test test/providers/settings_provider_test.dart
```

See [docs/TESTING.md](docs/TESTING.md) for the testing guide.

## Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

## Screens

| Screen | Description |
|---|---|
| Splash | Gradient logo, tagline, offline/free/no-account badges |
| Home | SELECT VIDEO circle, recent conversions, settings gear |
| Conversion Options | Video preview, output name, quality pills, CONVERT NOW |
| Converting | 240dp progress ring, percentage, time remaining, cancel |
| Success | Checkmark, audio preview, file info, CONVERT ANOTHER, DELETE/SHARE |
| Error | Broken-disc illustration, error code chip, retry/select another |
| History | Search bar, filter chips, date-grouped list, overflow menus |
| Settings | Remove Ads, quality, normalize volume, dark mode, auto-delete, storage, about |

## Configuration

| Setting | Location | Notes |
|---|---|---|
| Ad Unit IDs | `lib/constants/app_constants.dart` | Switch test → production before release |
| IAP Product ID | `lib/constants/app_constants.dart` | `remove_ads` |
| Min SDK | `android/app/build.gradle.kts` | 26 (Android 8.0) |
| Target SDK | `android/app/build.gradle.kts` | 34 (Android 14) |

## License

Proprietary — all rights reserved.