# Setup Guide

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | 3.24+ | `flutter --version` |
| Dart SDK | 3.10+ | Bundled with Flutter |
| Android Studio | Latest | Android SDK + emulator |
| Android SDK | API 26–35 | via SDK Manager |
| NDK | 25.1.8937393 | Required for FFmpeg Kit |

## Steps

### 1. Install Flutter

```bash
# macOS (via Homebrew)
brew install --cask flutter

# Verify
flutter doctor
```

### 2. Clone the Project

```bash
git clone <repo-url>
cd audiopeel
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Android SDK Configuration

Open Android Studio → SDK Manager → ensure these are installed:

- Android SDK Platform 35 (compile SDK)
- Android SDK Platform 26 (min SDK for testing)
- Android SDK Build-Tools 35.0.0
- NDK 25.1.8937393

### 5. Run on Emulator or Device

```bash
# List available devices
flutter devices

# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>
```

### 6. AdMob Configuration

Test ad units are pre-configured in `lib/constants/app_constants.dart`:

```dart
static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
```

For production, replace with your real AdMob ad unit IDs and update `AndroidManifest.xml`:

```xml
<meta-data
  android:name="com.google.android.gms.ads.APPLICATION_ID"
  android:value="YOUR_REAL_APP_ID" />
```

### 7. IAP Configuration

The product ID `remove_ads` must be created in the Google Play Console:

1. Go to Play Console → Monetise → Products → In-app products
2. Create a non-consumable product with ID `remove_ads`
3. Set price to $1.99
4. Activate the product

For testing, use a [license test account](https://developer.android.com/google/play/billing/test).

### 8. Signing (Release Builds)

```bash
# Generate a keystore
keytool -genkey -v -keystore ~/audiopeel-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias audiopeel

# Create android/key.properties (gitignored)
echo "storePassword=<password>
keyPassword=<password>
keyAlias=audiopeel
storeFile=/Users/<you>/audiopeel-release.jks" > android/key.properties
```

## Troubleshooting

| Issue | Solution |
|---|---|
| NDK not found | Install NDK 25.1.8937393 via SDK Manager |
| FFmpeg build fails | Ensure minSdk 26 in `build.gradle.kts` |
| AdMob crash on startup | Verify `APPLICATION_ID` in `AndroidManifest.xml` |
| Tests fail with `MissingPluginException` | Run `flutter clean && flutter pub get` |
