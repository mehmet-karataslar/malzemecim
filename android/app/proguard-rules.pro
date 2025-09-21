# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Mobile Scanner
-keep class dev.steenbakker.mobile_scanner.** { *; }

# Camera
-keep class androidx.camera.** { *; }

# Barcode scanning
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Play Core Library - Fix for missing classes
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }