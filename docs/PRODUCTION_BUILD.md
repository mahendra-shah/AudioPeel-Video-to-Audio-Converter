# Production Build Checklist for AudioPeel

## ⚠️ CRITICAL: AdMob Production Mode

### The Problem
The app defaults to **TEST AD IDs** for safety during development. Submitting to Google Play with test ad IDs will result in:
- **Automatic rejection** of your app submission
- **Potential account suspension** from AdMob/Google Play

### The Solution
**ALWAYS** build release versions with the production flag:

```bash
flutter build appbundle --release --dart-define=PRODUCTION=true
```

### Why This Matters
- `--dart-define=PRODUCTION=true` switches from test ad IDs to real ad IDs
- Test ad IDs show "Test Ad" labels and fake advertiser content
- Production ad IDs show real advertiser content and generate revenue

## Step-by-Step Production Build

### 1. Clean Build Environment
```bash
flutter clean
flutter pub get
```

### 2. Build Release Bundle (CORRECT WAY ✅)
```bash
flutter build appbundle --release --dart-define=PRODUCTION=true
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### 3. Build Release APK (For Testing - CORRECT WAY ✅)
```bash
flutter build apk --release --dart-define=PRODUCTION=true
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### 4. ❌ INCORRECT - Never Do This for Release
```bash
# WRONG - Uses test ad IDs
flutter build appbundle --release

# WRONG - Debug mode
flutter build appbundle

# WRONG - Missing flag
flutter build apk --release
```

## Verification Steps

### After Building, Test on Physical Device:

1. **Install the release build:**
```bash
flutter install --release
# Or manually: adb install build/app/outputs/flutter-apk/app-release.apk
```

2. **Check ads display correctly:**
   - Launch app
   - Navigate to home screen
   - Verify banner ad shows **real advertiser content** (not "Test Ad" label)
   - Convert a video
   - Verify interstitial ad shows **real advertiser content**
   - Ads should show brands like: Nike, McDonald's, apps, games, etc.

3. **Verify App ID in logs:**
   - Watch logcat for AdMob initialization
   - Should see: `ca-app-pub-5583038215571668~2159652952`
   - Should NOT see: `ca-app-pub-3940256099942544...` (test ID)

### Runtime Warning System

The app includes a safety check in `lib/main.dart` that logs a warning if you accidentally build a release without production mode:

```dart
if (kReleaseMode && !Env.isProduction) {
  Logger.warning('⚠️ RELEASE BUILD with TEST AD IDs!', 'Main');
}
```

**If you see this warning:** Stop immediately and rebuild with `--dart-define=PRODUCTION=true`

## Production Configuration Files

### Environment Variables ([lib/config/env.dart](lib/config/env.dart))
```dart
static const bool isProduction = bool.fromEnvironment(
  'PRODUCTION',
  defaultValue: false,  // Defaults to TEST for safety
);
```

### Ad IDs Configuration
- **Test Banner ID:** `ca-app-pub-3940256099942544/6300978111` (used when `isProduction = false`)
- **Test Interstitial ID:** `ca-app-pub-3940256099942544/1033173712`
- **Production App ID:** `ca-app-pub-5583038215571668~2159652952` (your real account)
- **Production Banner ID:** Set in `env.dart` (defaults for account)
- **Production Interstitial ID:** Set in `env.dart` (defaults for account)

## Pre-Submission Checklist

Before uploading to Play Console:

- [ ] Built with `--dart-define=PRODUCTION=true` flag
- [ ] Tested on physical device (not just emulator)
- [ ] Verified real ads appear (no "Test Ad" labels)
- [ ] Banner ad loads on home screen with real content
- [ ] Interstitial ad shows after conversion with real content
- [ ] "Remove Ads" IAP works correctly
- [ ] Ads disappear after purchase
- [ ] App ID matches: `ca-app-pub-5583038215571668~2159652952`
- [ ] No crashes or errors in production mode
- [ ] Version code/name updated in `pubspec.yaml`

## Common Mistakes to Avoid

1. **Forgetting the flag** → Most common mistake
2. **Building debug by accident** → Check you typed `--release`
3. **Not testing before upload** → Always test on device first
4. **Mixing up APK and AAB** → Upload AAB to Play Console, not APK
5. **Testing on emulator only** → Real devices handle ads differently

## Quick Reference

| Build Type | Command | Ad Mode | Use Case |
|------------|---------|---------|----------|
| Debug (Dev) | `flutter run` | TEST | Local development |
| Debug APK | `flutter build apk` | TEST | QA testing |
| Release APK (Test) | `flutter build apk --release` | TEST | Final testing before production |
| **Release APK (Prod)** | `flutter build apk --release --dart-define=PRODUCTION=true` | **PRODUCTION** | **Testing production ads** |
| **Release AAB (Prod)** | `flutter build appbundle --release --dart-define=PRODUCTION=true` | **PRODUCTION** | **Play Store upload** |

## Troubleshooting

### "Test Ad" Still Showing After Prod Build
- Uninstall the old version completely
- Clear AdMob cache on device (Settings → Apps → Google Play Services → Storage → Clear Cache)
- Reinstall fresh production build
- Wait 5-10 minutes for ad caching to refresh

### Ads Not Loading
- Check internet connection
- Verify AdMob account is approved and active
- Check for any AdMob policy violations
- Ensure ad units are created in AdMob console
- Check logcat for AdMob error messages

### IAP Not Working in Production
- Verify signing key matches Play Console
- Ensure app is uploaded to Play Console (IAP only works with published app)
- Check product ID matches: `remove_ads`
- Product must be activated in Play Console

## Documentation References

- [Play Store Publishing Guide](../PLAYSTORE_PUBLISHING_GUIDE.md)
- [Release Documentation](./RELEASE.md)
- [AdMob Setup](../lib/config/env.dart)

---

**Remember:** One wrong build can lead to account suspension. Always double-check you're using production mode for release builds!
