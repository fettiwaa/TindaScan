# R8 keep rules for TindaScan release builds.
# Firebase and ML Kit ship consumer rules in their AARs; these cover the
# reflection-based pieces that are commonly stripped by mistake.

# flutter_local_notifications uses Gson to persist scheduled notifications.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# ML Kit barcode scanning (mobile_scanner).
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
