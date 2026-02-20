# Release Build Guide

This document explains how to build AudioPeel for release and publish to the Google Play Store.

---

## Prerequisites

| Tool | Minimum Version |
|------|----------------|
| Flutter | 3.24+ |
| Dart | 3.10+ |
| Android SDK | 34 (target), 26 (min) |
| Java / JDK | 17 |
| keytool | (bundled with JDK) |

---

## 1. Generate a Signing Keystore

```bash
keytool -genkey -v \
  -keystore ~/audiopeel-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias audiopeel
```

> **Keep this file safe.** If lost you can never update the app on the Play Store.

## 2. Configure `key.properties`

Copy the example and fill in your values:

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=audiopeel
storeFile=/Users/you/audiopeel-release.jks
```

> `key.properties` is git-ignored. Never commit it.

## 3. Set Production AdMob IDs

Replace the test app ID in `android/app/src/main/res/values/strings.xml`:

```xml
<string name="admob_app_id" translatable="false">ca-app-pub-XXXX~YYYY</string>
```

Then pass the ad-unit IDs at build time:

```bash
flutter build apk --release \
  --dart-define=PRODUCTION=true \
  --dart-define=ADMOB_APP_ID=ca-app-pub-XXXX~YYYY \
  --dart-define=BANNER_AD_UNIT_ID=ca-app-pub-XXXX/ZZZZ \
  --dart-define=INTERSTITIAL_AD_UNIT_ID=ca-app-pub-XXXX/WWWW
```

## 4. Build Release APK

```bash
flutter build apk --release \
  --dart-define=PRODUCTION=true \
  --dart-define=BANNER_AD_UNIT_ID=ca-app-pub-XXXX/ZZZZ \
  --dart-define=INTERSTITIAL_AD_UNIT_ID=ca-app-pub-XXXX/WWWW
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## 5. Build Release AAB (for Play Store)

```bash
flutter build appbundle --release \
  --dart-define=PRODUCTION=true \
  --dart-define=BANNER_AD_UNIT_ID=ca-app-pub-XXXX/ZZZZ \
  --dart-define=INTERSTITIAL_AD_UNIT_ID=ca-app-pub-XXXX/WWWW
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## 6. Verify the Release Build

### Check APK size
```bash
ls -lh build/app/outputs/flutter-apk/app-release.apk
# Target: < 30 MB
```

### Install on device
```bash
flutter install --release
```

### Verify ProGuard shrinking
```bash
# Check that R8/ProGuard ran (look for mapping.txt)
ls -la build/app/outputs/mapping/release/
```

---

## Build Flavors (Optional)

For CI/CD, create a `dart_define.env` file:

```env
PRODUCTION=true
ADMOB_APP_ID=ca-app-pub-XXXX~YYYY
BANNER_AD_UNIT_ID=ca-app-pub-XXXX/ZZZZ
INTERSTITIAL_AD_UNIT_ID=ca-app-pub-XXXX/WWWW
```

Then build with:
```bash
flutter build appbundle --release --dart-define-from-file=dart_define.env
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **Signing error** | Verify `key.properties` path and passwords |
| **ProGuard crash** | Check `proguard-rules.pro` — add `-keep` for missing classes |
| **AdMob test ads in release** | Ensure `--dart-define=PRODUCTION=true` is passed |
| **Large APK** | Run `flutter build apk --analyze-size` to find bloat |
| **Missing native libs** | Verify NDK version `25.1.8937393` in build.gradle.kts |

---

## Play Store Submission

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app → "AudioPeel"
3. Upload the `.aab` file
4. Fill in store listing (see `LAUNCH_CHECKLIST.md`)
5. Complete content rating questionnaire
6. Set pricing (Free with ads + IAP)
7. Submit for review
