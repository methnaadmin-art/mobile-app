# Project-specific R8 rules can be added here when a release dependency requires it.

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Billing
-keep class com.android.billingclient.** { *; }

# Google Play Core (required by Flutter embedding even without deferred components)
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.listener.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.listener.**
-dontwarn com.google.android.play.core.splitcompat.**

# Google Play Services
-keep class com.google.android.gms.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Firebase Crashlytics — must be kept for crash reporting in release
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.google.firebase.crashlytics.** { *; }
-keepnames class com.google.firebase.crashlytics.FirebaseCrashlytics
-keep class * extends com.google.firebase.crashlytics.internal.model.CrashlyticsReport { *; }

# Dio / HTTP
-dontwarn okio.**
-dontwarn org.conscrypt.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Socket.IO
-keep class io.socket.** { *; }

# GetX
-keep class com.get.** { *; }

# Gson / JSON serialization (used by some plugins)
-keepattributes Signature
-keepattributes *Annotation*

# ICU / Unicode text shaping (Arabic, RTL)
-keep class com.ibm.icu.** { *; }
-keep class android.icu.** { *; }
-dontwarn com.ibm.icu.**

# Google Fonts HTTP fetching (safety net)
-keep class com.google.fonts.** { *; }
-dontwarn com.google.android.gms.fonts.**

