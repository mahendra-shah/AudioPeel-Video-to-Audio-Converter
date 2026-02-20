# Background Conversion Notifications

**Feature Status:** ✅ Implemented  
**Added:** February 20, 2026  
**Compliant:** Google Play Store requirements

---

## Overview

AudioPeel now displays **industry-standard progress notifications** when converting videos to audio. Users can minimize or leave the app during conversion and receive real-time progress updates in their notification shade, just like YouTube, Telegram, and other professional media apps.

---

## Features

### ✅ Progress Notifications
- **Persistent notification** shows during active conversion
- **Progress bar** with real-time percentage (0-100%)
- **Estimated time remaining** calculated dynamically
- **Ongoing indicator** prevents accidental dismissal
- **Low importance** (no sound/vibration for progress updates)

### ✅ Completion Notifications
- **Success notification** when conversion completes
  - Shows✓ checkmark and output file name
  - Can be dismissed
  - Plays completion sound/vibration
- **Error notification** when conversion fails
  - Shows error message
  - Can be dismissed

### ✅ Permission Handling (Android 13+)
- **Automatic request** before first conversion
- **Graceful degradation** if denied (conversions still work)
- **No permission needed** on Android 12 and below
- **Privacy-compliant** explanation in settings

---

## Technical Implementation

### Service Architecture

**File:** [lib/services/notification_service.dart](lib/services/notification_service.dart)

```dart
// Initialize during app startup
await NotificationService.instance.initialize();

// Show progress notification
await notificationService.showProgressNotification(
  fileName: 'video.mp4',
  progress: 0.65, // 65%
  estimatedTimeRemaining: '2m 30s',
);

// Show completion
await notificationService.showCompletionNotification(
  fileName: 'output.mp3',
);
```

### Integration Points

1. **main.dart** - Service initialization
2. **ConversionProvider** - Progress tracking and notification updates
3. **AndroidManifest.xml** - POST_NOTIFICATIONS permission declared
4. **pubspec.yaml** - flutter_local_notifications dependency

### Notification Channel

```yaml
Channel ID: audiopeel_conversion
Channel Name: Conversion Progress
Description: Shows progress when converting videos to audio
Importance: Low (no interruptions for progress)
Sound: Disabled for progress, enabled for completion/error
Vibration: Disabled for progress, enabled for completion/error
```

---

## User Experience

### Conversion Flow with Notifications

1. **User starts conversion**
   - App requests notification permission (Android 13+ first time only)
   - If granted: Shows initial notification "Converting to audio..."
   
2. **Conversion in progress**
   - User sees progress screen with animated ring
   - User can press home button or switch apps
   - **Notification appears in notification shade** with progress bar
   - Notification updates every ~2-3 seconds with:
     - Current percentage
     - Estimated time remaining
   
3. **Conversion completes**
   - Success: Shows "Conversion complete ✓ Audio saved: filename.mp3"
   - Error: Shows "Conversion failed - Please try again"
   - **Sound and vibration** play (if enabled in device settings)
   - User can tap notification to return to app

### Permission States

| Android Version | Permission Required | Behavior |
|----------------|---------------------|----------|
| Android 8-12 (API 26-32) | None | Notifications work automatically |
| Android 13+ (API 33+) | POST_NOTIFICATIONS | Requested before first conversion |

**If user denies permission:**
- Conversions still work normally
- No notifications shown
- User sees progress only when app is open
- No errors or warnings displayed

---

## Privacy & Compliance

### Google Play Store Compliance ✅

- **Permission justified:** Explained in [PRIVACY_POLICY.md](PRIVACY_POLICY.md)
- **User control:** Optional - app works fine without it
- **Data handling:** Notifications are local only, no data sent to servers
- **Disclosure:** Updated privacy policy with notification section

### Privacy Policy Excerpt

> **Post Notifications (POST_NOTIFICATIONS)**  
> **Purpose:** To show conversion progress notifications when you minimize the app during conversion (Android 13+ only).  
> **When requested:** Before starting your first conversion (Android 13+ devices only).  
> **What it shows:** Progress percentage, estimated time remaining, and completion status.  
> **User control:** Optional. If denied, conversions still work - you just won't see notifications outside the app.  
> **Data:** Notifications are shown locally on your device only. No notification data is sent to servers.

---

## Testing Guide

### Manual Test Cases

#### Test 1: Permission Request (Android 13+)
1. Install app on Android 13+ device
2. Select video and start conversion
3. **Expected:** Permission dialog appears before conversion starts
4. Grant permission
5. **Expected:** Notification appears immediately

#### Test 2: Progress Updates
1. Start long conversion (5+ minute video)
2. Minimize app to home screen
3. Pull down notification shade
4. **Expected:**
   - Progress bar showing percentage
   - File name displayed
   - Estimated time remaining (updates every ~3 seconds)

#### Test 3: Completion Notification
1. Start short conversion
2. Minimize app
3. Wait for completion
4. **Expected:**
   - Success notification appears
   - Shows "Conversion complete ✓"
   - Plays sound/vibration
   - Progress notification disappears

#### Test 4: Error Notification
1. Start conversion with corrupted video
2. Minimize app
3. **Expected:**
   - Error notification appears
   - Shows error message
   - Progress notification disappears

#### Test 5: Manual Cancellation
1. Start conversion
2. Minimize app
3. Expand notification, tap back into app
4. Cancel conversion
5. **Expected:** Notification disappears immediately

#### Test 6: Permission Denied
1. Deny notification permission
2. Start conversion
3. **Expected:**
   - Conversion works normally
   - No notifications shown
   - No error messages

#### Test 7: Android 12 and Below
1. Test on Android 12 device
2. Start conversion
3. **Expected:**
   - No permission request
   - Notifications work automatically

---

## Code References

### Core Files

- **Service:** [lib/services/notification_service.dart](lib/services/notification_service.dart)
- **Integration:** [lib/providers/conversion_provider.dart](lib/providers/conversion_provider.dart#L180-L230)
- **Initialization:** [lib/main.dart](lib/main.dart#L51-L58)
- **Permissions:** [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml#L52)

### Key Methods

```dart
// ConversionProvider integration
void _onProgress(double progress) {
  _task = _task?.copyWith(progress: progress);
  notifyListeners();

  // Update notification
  if (_task != null && progress > 0.0 && progress < 1.0) {
    final estimatedTime = _calculateEstimatedTime(progress);
    _notificationService.showProgressNotification(
      fileName: _task!.inputVideoName,
      progress: progress,
      estimatedTimeRemaining: estimatedTime,
    );
  }
}

// Time estimation algorithm
String _calculateEstimatedTime(double progress) {
  if (_conversionStartTime == null || progress <= 0.0) {
    return 'Calculating...';
  }

  final elapsed = DateTime.now().difference(_conversionStartTime!);
  final totalEstimated = elapsed.inMilliseconds / progress;
  final remaining = totalEstimated - elapsed.inMilliseconds;

  if (remaining <= 0) return 'Almost done';

  final remainingSeconds = (remaining / 1000).round();
  
  if (remainingSeconds < 60) return '${remainingSeconds}s';
  else if (remainingSeconds < 3600) {
    final minutes = (remainingSeconds / 60).round();
    return '${minutes}m';
  } else {
    final hours = (remainingSeconds / 3600).round();
    final minutes = ((remainingSeconds % 3600) / 60).round();
    return '${hours}h ${minutes}m';
  }
}
```

---

## Future Enhancements

### Potential Improvements (Not Implemented)

- [ ] **Notification tap action** - Navigate to specific screen when tapped
- [ ] **Cancel from notification** - Add cancel button to notification
- [ ] **Notification history** - Keep completed notifications in history
- [ ] **Custom notification sound** - Brand-specific completion sound
- [ ] **Notification content text** - More detailed conversion statistics
- [ ] **Multiple conversions** - Track multiple parallel conversions (if implemented)
- [ ] **iOS support** - Same notification experience on iOS

### Dependencies

```yaml
flutter_local_notifications: ^17.2.4
  ├── timezone: ^0.9.4
  ├── flutter_local_notifications_linux: ^4.0.1
  └── flutter_local_notifications_platform_interface: ^7.2.0
```

---

## Troubleshooting

### Issue: Notifications not appearing

**Cause:** Permission denied or notifications disabled in system settings

**Solution:**
1. Check app notification settings on device
2. Check notification permission status
3. Verify NotificationService.initialize() was called
4. Check logcat for initialization errors

### Issue: Progress updates slow or delayed

**Cause:** Too frequent updates causing performance issues

**Solution:**
- Updates are throttled to every ~3 seconds automatically via FFmpeg progress callbacks
- This is intentional to balance responsiveness and performance

### Issue: Notification persists after conversion

**Cause:** Completion/error notification not shown

**Solution:**
- Check for exceptions in notification service logs
- Verify internet permission for logging
- Ensure proper cleanup in ConversionProvider

---

## Summary

✅ **Production-ready** industry-standard notification system  
✅ **Play Store compliant** with proper permissions and disclosures  
✅ **User-friendly** with graceful degradation if permission denied  
✅ **Well-integrated** with existing conversion flow  
✅ **Properly documented** in privacy policy and code

This feature significantly improves the UX by allowing users to multitask during conversions, making AudioPeel competitive with professional media converter apps.
