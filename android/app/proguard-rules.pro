# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Audioplayers & Media
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }

# Serialization & Annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod


# Flutter Play Core & Deferred Components
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.**

# Google Mobile Ads, UMP & AndroidX Startup / WorkManager
-keep class io.flutter.plugins.googlemobileads.** { *; }
-keep class com.google.android.gms.ads.MobileAds { *; }
-keep class com.google.android.gms.ads.MobileAdsInitProvider { *; }
-keep class com.google.android.gms.ads.AdActivity { *; }
-keep class com.google.android.gms.ads.initialization.** { *; }
-keep class com.google.android.gms.ads.interstitial.** { *; }
-keep class com.google.android.gms.ads.rewardedinterstitial.** { *; }
-keep class com.google.android.gms.ads.rewarded.** { *; }
-keep class com.google.android.gms.ads.internal.** { *; }
-keep class com.google.android.ump.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.startup.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.ump.**
