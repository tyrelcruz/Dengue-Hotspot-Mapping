# Keep Google Play Services classes
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep your app's classes
-keep class com.example.buzzmap.** { *; } 