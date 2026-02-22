# ─── Flutter engine ─────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ─── FFmpeg Kit ─────────────────────────────────────────────────────
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.** { *; }
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep class N2.** { *; }

# ─── Google Mobile Ads ─────────────────────────────────────────────
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# ─── In-App Billing ───────────────────────────────────────────────
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }

# ─── SQFlite / SQLCipher ──────────────────────────────────────────
-keep class io.flutter.plugins.sqflite.** { *; }
-keep class org.sqlite.** { *; }
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# ─── SharedPreferences ────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ─── Kotlin (suppress warnings) ──────────────────────────────────
-dontwarn kotlin.**
-dontwarn kotlinx.**

# ─── Google Play Core (deferred components — not used) ────────────
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ─── General ──────────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
