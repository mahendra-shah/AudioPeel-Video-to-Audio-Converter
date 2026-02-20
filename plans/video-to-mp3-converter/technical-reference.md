# Technical Implementation Reference

**Project:** AudioPeel - Video to MP3 Converter  
**Last Updated:** 6 February 2026

---

## Package Verification Status

**CRITICAL:** Before using ANY package, verify on pub.dev first. Below are pre-verified packages as of Feb 2026.

### Core Dependencies (✅ Verified)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.2  # https://pub.dev/packages/provider
  
  # Media Processing  
  ffmpeg_kit_flutter: ^6.0.3  # https://pub.dev/packages/ffmpeg_kit_flutter
  # NOTE: Use "ffmpeg_kit_flutter" NOT "ffmpeg_kit_flutter_new"
  
  # Permissions
  permission_handler: ^11.3.1  # https://pub.dev/packages/permission_handler
  
  # File Operations
  path_provider: ^2.1.4  # https://pub.dev/packages/path_provider
  file_picker: ^8.0.5  # https://pub.dev/packages/file_picker
  
  # Database
  sqflite: ^2.3.3+1  # https://pub.dev/packages/sqflite
  
  # Ads & Monetization
  google_mobile_ads: ^5.1.0  # https://pub.dev/packages/google_mobile_ads
  in_app_purchase: ^3.2.0  # https://pub.dev/packages/in_app_purchase
  
  # UI Utilities
  shimmer: ^3.0.0  # https://pub.dev/packages/shimmer
  flutter_animate: ^4.5.0  # https://pub.dev/packages/flutter_animate
  
  # Utilities
  intl: ^0.19.0  # https://pub.dev/packages/intl
  shared_preferences: ^2.3.2  # https://pub.dev/packages/shared_preferences

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  mockito: ^5.4.4  # For unit tests
```

---

## FFmpeg Commands Reference

### Basic MP3 Conversion

```dart
// 128 kbps
String command = '-i "$inputPath" -vn -ar 44100 -ac 2 -b:a 128k "$outputPath"';

// 192 kbps (recommended)
String command = '-i "$inputPath" -vn -ar 44100 -ac 2 -b:a 192k "$outputPath"';

// 320 kbps (high quality)
String command = '-i "$inputPath" -vn -ar 44100 -ac 2 -b:a 320k "$outputPath"';
```

### Command Breakdown
- `-i "$inputPath"`: Input video file
- `-vn`: No video (audio only)
- `-ar 44100`: Audio sample rate 44.1 kHz (CD quality)
- `-ac 2`: 2 audio channels (stereo)
- `-b:a 192k`: Audio bitrate 192 kbps
- `"$outputPath"`: Output MP3 file

### Get Video Metadata

```dart
// Get duration, codec, bitrate
String command = '-i "$videoPath"';
// Parse FFmpeg output stderr for metadata
```

### Progress Tracking

```dart
// FFmpeg Kit provides progress callbacks
FFmpegKit.executeAsync(
  command,
  (session) async {
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      // Conversion successful
    } else {
      // Conversion failed
    }
  },
  (log) {
    // Log messages
  },
  (statistics) {
    // Progress statistics
    final time = statistics.getTime(); // Current position in milliseconds
    final size = statistics.getSize(); // Output file size in bytes
    final bitrate = statistics.getBitrate(); // Current bitrate
    
    // Calculate percentage based on video duration
    // percentage = (time / totalDuration) * 100
  },
);
```

---

## Android Permissions Configuration

### AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:label="AudioPeel"
        android:requestLegacyExternalStorage="true">
        
        <!-- AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
            
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
    
    <!-- Permissions -->
    <!-- For Android 10+ (API 29+): No explicit storage permission needed with SAF -->
    <!-- For Android 8-9 (API 26-28): Need legacy storage permission -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="29"/>
    <uses-permission android:name="android.permission.INTERNET"/> <!-- For ads -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/> <!-- For ads -->
</manifest>
```

### build.gradle (app-level)

```gradle
android {
    namespace 'com.audiopeel.app'
    compileSdkVersion 34
    ndkVersion "25.1.8937393"  // Required for FFmpeg
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = '1.8'
    }
    
    defaultConfig {
        applicationId "com.audiopeel.app"
        minSdkVersion 26  // Android 8.0
        targetSdkVersion 34  // Android 14
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true  // For large dependencies
    }
    
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
}
```

### proguard-rules.pro

```proguard
# Keep FFmpeg Kit classes
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.** { *; }

# Keep Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Keep IAP
-keep class com.android.billingclient.** { *; }
```

---

## File Structure & Naming Conventions

### Directory Structure (Enforced)

```
lib/
├── main.dart                           # Entry point only
├── app.dart                            # MaterialApp + routing
├── constants/
│   ├── app_colors.dart                # Color(0xFFXXXXXX) constants
│   ├── app_strings.dart               # All UI strings
│   ├── app_constants.dart             # Magic numbers, config
│   └── app_theme.dart                 # ThemeData for light/dark
├── models/
│   ├── audio_quality.dart             # Enum: low128, medium192, high320
│   ├── conversion_task.dart           # Data class
│   └── audio_file.dart                # Data class
├── providers/
│   ├── conversion_provider.dart       # extends ChangeNotifier
│   ├── history_provider.dart          # extends ChangeNotifier
│   ├── settings_provider.dart         # extends ChangeNotifier
│   └── ad_provider.dart               # extends ChangeNotifier
├── services/
│   ├── ffmpeg_service.dart            # Pure business logic
│   ├── storage_service.dart           # File I/O
│   ├── database_service.dart          # SQLite operations
│   ├── permission_service.dart        # Permission checks
│   ├── ad_service.dart                # AdMob wrapper
│   └── iap_service.dart               # IAP wrapper
├── screens/
│   ├── splash_screen.dart             # Initial screen
│   ├── home_screen.dart               # Main screen
│   ├── conversion_options_screen.dart # Quality selection
│   ├── converting_screen.dart         # Progress
│   ├── success_screen.dart            # Completion
│   ├── error_screen.dart              # Error handling
│   ├── history_screen.dart            # All conversions
│   └── settings_screen.dart           # App settings
├── widgets/
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
    ├── file_utils.dart                # File helpers
    ├── format_utils.dart              # Date, duration formatting
    ├── validation_utils.dart          # Input validation
    └── logger.dart                    # Logging utility
```

### Naming Conventions (Dart Official)

```dart
// Files: lowercase_with_underscores.dart
lib/screens/conversion_options_screen.dart
lib/services/ffmpeg_service.dart

// Classes: UpperCamelCase
class ConversionProvider extends ChangeNotifier {}
class AudioFile {}

// Variables, functions: lowerCamelCase
String outputFileName = 'audio.mp3';
void startConversion() {}

// Constants: lowerCamelCase (preferred) or SCREAMING_SNAKE_CASE
const int maxFileNameLength = 50;
const Color primaryBlue = Color(0xFF2563EB);

// Private: _leading underscore
String _privateMethod() {}
int _internalState = 0;

// Enums: UpperCamelCase, values: lowerCamelCase
enum AudioQuality { low128, medium192, high320 }
```

---

## Database Schema (SQLite)

### Table: conversions

```sql
CREATE TABLE conversions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    input_video_name TEXT NOT NULL,          -- e.g., "vacation_video.mp4"
    input_video_path TEXT NOT NULL,          -- Full path to original video
    output_audio_name TEXT NOT NULL,         -- e.g., "vacation_video_audio.mp3"
    output_audio_path TEXT NOT NULL,         -- Full path to MP3 file
    quality INTEGER NOT NULL,                -- 128, 192, or 320 (kbps)
    file_size INTEGER NOT NULL,              -- In bytes
    duration INTEGER NOT NULL,               -- In seconds
    status TEXT NOT NULL,                    -- 'completed' or 'failed'
    created_at INTEGER NOT NULL,             -- Unix timestamp (milliseconds)
    error_message TEXT                       -- NULL if successful, error text if failed
);

-- Indexes for faster queries
CREATE INDEX idx_created_at ON conversions(created_at DESC);
CREATE INDEX idx_quality ON conversions(quality);
CREATE INDEX idx_status ON conversions(status);
```

### Query Examples

```dart
// Get all successful conversions (newest first)
SELECT * FROM conversions 
WHERE status = 'completed' 
ORDER BY created_at DESC;

// Get today's conversions
SELECT * FROM conversions 
WHERE status = 'completed' 
  AND created_at >= ?  -- Unix timestamp of today 00:00:00
ORDER BY created_at DESC;

// Get last 7 days
SELECT * FROM conversions 
WHERE status = 'completed' 
  AND created_at >= ?  -- Unix timestamp 7 days ago
ORDER BY created_at DESC;

// Get high quality only (320 kbps)
SELECT * FROM conversions 
WHERE status = 'completed' 
  AND quality = 320
ORDER BY created_at DESC;

// Search by filename
SELECT * FROM conversions 
WHERE status = 'completed' 
  AND (input_video_name LIKE ? OR output_audio_name LIKE ?)
ORDER BY created_at DESC;

// Delete conversion
DELETE FROM conversions WHERE id = ?;

// Clear all history
DELETE FROM conversions;

// Get total count
SELECT COUNT(*) FROM conversions WHERE status = 'completed';
```

---

## State Management Patterns

### Provider Setup (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await DatabaseService.instance.init();
  await SettingsService.instance.init();
  MobileAds.instance.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConversionProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Provider Pattern (Example: ConversionProvider)

```dart
class ConversionProvider extends ChangeNotifier {
  // State
  File? _selectedVideo;
  String _outputName = '';
  AudioQuality _quality = AudioQuality.medium192;
  double _progress = 0.0;
  bool _isConverting = false;
  String? _error;
  int _estimatedTime = 0;
  
  // Getters (read-only access)
  File? get selectedVideo => _selectedVideo;
  String get outputName => _outputName;
  AudioQuality get quality => _quality;
  double get progress => _progress;
  bool get isConverting => _isConverting;
  String? get error => _error;
  int get estimatedTime => _estimatedTime;
  
  // Services (injected via constructor)
  final FFmpegService _ffmpegService;
  final StorageService _storageService;
  
  ConversionProvider({
    FFmpegService? ffmpegService,
    StorageService? storageService,
  })  : _ffmpegService = ffmpegService ?? FFmpegService(),
        _storageService = storageService ?? StorageService();
  
  // Methods (business logic)
  Future<void> selectVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    
    if (result != null && result.files.single.path != null) {
      _selectedVideo = File(result.files.single.path!);
      _outputName = '${_selectedVideo!.name.split('.').first}_audio';
      _error = null;
      
      // Calculate estimated time
      final metadata = await _ffmpegService.getVideoMetadata(_selectedVideo!.path);
      _estimatedTime = _ffmpegService.estimateConversionTime(
        metadata.duration,
        _quality,
      );
      
      notifyListeners();
    }
  }
  
  void updateOutputName(String name) {
    _outputName = name;
    notifyListeners();
  }
  
  void selectQuality(AudioQuality quality) {
    _quality = quality;
    notifyListeners();
  }
  
  Future<void> startConversion() async {
    if (_selectedVideo == null) return;
    
    _isConverting = true;
    _progress = 0.0;
    _error = null;
    notifyListeners();
    
    try {
      final outputPath = await _storageService.getOutputPath(_outputName);
      
      await _ffmpegService.convertVideoToMP3(
        inputPath: _selectedVideo!.path,
        outputPath: outputPath,
        quality: _quality,
        onProgress: (progress) {
          _progress = progress;
          notifyListeners();
        },
      );
      
      // Success - save to history
      await DatabaseService.instance.insertConversion(/* ... */);
      
      _isConverting = false;
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      _isConverting = false;
      notifyListeners();
    }
  }
  
  Future<void> cancelConversion() async {
    await _ffmpegService.cancelConversion();
    _isConverting = false;
    _progress = 0.0;
    notifyListeners();
  }
  
  void reset() {
    _selectedVideo = null;
    _outputName = '';
    _quality = AudioQuality.medium192;
    _progress = 0.0;
    _isConverting = false;
    _error = null;
    _estimatedTime = 0;
    notifyListeners();
  }
}
```

### Consuming Provider in Widget

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Consumer rebuilds only when needed
          Consumer<HistoryProvider>(
            builder: (context, historyProvider, child) {
              if (historyProvider.isLoading) {
                return CircularProgressIndicator();
              }
              
              if (historyProvider.conversions.isEmpty) {
                return EmptyState();
              }
              
              return ListView.builder(
                itemCount: historyProvider.conversions.length,
                itemBuilder: (context, index) {
                  final conversion = historyProvider.conversions[index];
                  return ConversionCard(conversion: conversion);
                },
              );
            },
          ),
          
          // Direct access (no rebuild)
          ElevatedButton(
            onPressed: () {
              // Access provider without listening
              context.read<ConversionProvider>().selectVideo();
            },
            child: Text('SELECT VIDEO'),
          ),
        ],
      ),
    );
  }
}
```

---

## AdMob Integration

### Ad Unit IDs (Test vs Production)

```dart
// lib/constants/app_constants.dart
class AdConfig {
  static const bool testMode = true; // Switch to false for production
  
  // Banner Ad Units
  static const String bannerAdUnitIdAndroid = testMode
      ? 'ca-app-pub-3940256099942544/6300978111'  // Test
      : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Real (get from AdMob)
  
  // Interstitial Ad Units
  static const String interstitialAdUnitIdAndroid = testMode
      ? 'ca-app-pub-3940256099942544/1033173712'  // Test
      : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Real (get from AdMob)
  
  // Ad Frequency
  static const int interstitialFrequency = 1; // Show after every X conversions
  
  // App ID (add to AndroidManifest.xml)
  static const String admobAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';
}
```

### Banner Ad Widget

```dart
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({Key? key}) : super(key: key);
  
  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _loadAd();
  }
  
  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitIdAndroid,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Banner ad failed to load: $error');
        },
      ),
    )..load();
  }
  
  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Check if ads are removed via IAP
    final adsRemoved = context.watch<SettingsProvider>().adsRemoved;
    if (adsRemoved) return const SizedBox.shrink();
    
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 50); // Placeholder
    }
    
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
```

### Interstitial Ad Service

```dart
class AdService {
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  
  // Singleton pattern
  static final AdService instance = AdService._internal();
  AdService._internal();
  
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitIdAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialReady = false;
              loadInterstitialAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialReady = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialReady = false;
        },
      ),
    );
  }
  
  Future<void> showInterstitialAd({bool checkRemovalStatus = true}) async {
    if (checkRemovalStatus) {
      final adsRemoved = await _checkAdsRemoved();
      if (adsRemoved) return; // Don't show if IAP purchased
    }
    
    if (!_isInterstitialReady || _interstitialAd == null) {
      print('Interstitial ad not ready');
      return;
    }
    
    await _interstitialAd!.show();
    _isInterstitialReady = false;
  }
  
  Future<bool> _checkAdsRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ads_removed') ?? false;
  }
  
  void dispose() {
    _interstitialAd?.dispose();
  }
}
```

---

## In-App Purchase (IAP) Implementation

### IAP Service

```dart
class IapService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Product IDs
  static const String removeAdsProductId = 'remove_ads_v1';
  
  // Singleton
  static final IapService instance = IapService._internal();
  IapService._internal();
  
  Future<void> initialize() async {
    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('IAP error: $error'),
    );
    
    // Restore previous purchases
    await restorePurchases();
  }
  
  Future<bool> isAvailable() async {
    return await _inAppPurchase.isAvailable();
  }
  
  Future<ProductDetails?> getRemoveAdsProduct() async {
    final available = await isAvailable();
    if (!available) return null;
    
    const Set<String> ids = {removeAdsProductId};
    final ProductDetailsResponse response = 
        await _inAppPurchase.queryProductDetails(ids);
    
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
      return null;
    }
    
    return response.productDetails.first;
  }
  
  Future<void> purchaseRemoveAds() async {
    final product = await getRemoveAdsProduct();
    if (product == null) {
      throw Exception('Product not available');
    }
    
    final purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }
  
  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }
  
  Future<bool> checkPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ads_removed') ?? false;
  }
  
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify purchase (in production, verify with backend)
        await _verifyAndSavePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        print('Purchase error: ${purchase.error}');
      }
      
      // Complete purchase
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }
  
  Future<void> _verifyAndSavePurchase(PurchaseDetails purchase) async {
    // In production: verify with backend server
    // For now: save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ads_removed', true);
    print('Purchase verified and saved');
  }
  
  void dispose() {
    _subscription.cancel();
  }
}
```

### Usage in Settings Screen

```dart
ElevatedButton(
  onPressed: () async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(child: CircularProgressIndicator()),
      );
      
      await IapService.instance.purchaseRemoveAds();
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ads removed successfully!')),
      );
      
      // Update settings provider
      context.read<SettingsProvider>().setAdsRemoved(true);
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    }
  },
  child: Row(
    children: [
      Icon(Icons.stars),
      SizedBox(width: 8),
      Text('REMOVE ADS & UNLOCK PRO'),
      Spacer(),
      Text('\$1.99'),
    ],
  ),
)
```

---

## Testing Utilities

### Mock Services for Unit Tests

```dart
// test/mocks/mock_ffmpeg_service.dart
class MockFFmpegService extends Mock implements FFmpegService {}

// test/mocks/mock_storage_service.dart
class MockStorageService extends Mock implements StorageService {}

// test/mocks/mock_database_service.dart
class MockDatabaseService extends Mock implements DatabaseService {}

// Usage in tests
void main() {
  late ConversionProvider provider;
  late MockFFmpegService mockFFmpeg;
  late MockStorageService mockStorage;
  
  setUp(() {
    mockFFmpeg = MockFFmpegService();
    mockStorage = MockStorageService();
    provider = ConversionProvider(
      ffmpegService: mockFFmpeg,
      storageService: mockStorage,
    );
  });
  
  test('startConversion updates progress', () async {
    // Arrange
    when(mockFFmpeg.convertVideoToMP3(
      inputPath: any,
      outputPath: any,
      quality: any,
      onProgress: any,
    )).thenAnswer((_) async {
      // Simulate progress callback
      final onProgress = _.namedArguments[#onProgress] as Function;
      onProgress(0.5); // 50% progress
    });
    
    // Act
    await provider.startConversion();
    
    // Assert
    expect(provider.progress, 0.5);
  });
}
```

---

## Performance Optimization Checklist

- [ ] Use `const` constructors for all immutable widgets
- [ ] Implement `ListView.builder` for large lists (not `ListView` with children)
- [ ] Use `RepaintBoundary` for expensive widgets
- [ ] Dispose controllers in `dispose()` method
- [ ] Cancel streams/subscriptions in `dispose()`
- [ ] Use `MediaQuery.of(context).size` sparingly (causes rebuilds)
- [ ] Cache expensive computations (memoization)
- [ ] Lazy-load images with `Image.network` + `cacheHeight`/`cacheWidth`
- [ ] Profile with DevTools (look for jank, overdraw)
- [ ] Enable ProGuard in release builds
- [ ] Use `flutter build apk --split-per-abi` for smaller APKs
- [ ] Optimize assets (compress images, use WebP)
- [ ] Minimize widget rebuilds (use `Consumer` selectively)

---

**END OF TECHNICAL REFERENCE**

This document should be consulted throughout implementation for exact specifications.
