# Google Play Services için proguard kuralları
-keep class com.google.android.gms.ads.identifier.** { *; }
-dontwarn com.google.android.gms.ads.identifier.**

# Google Play Services genel kurallar
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Kotlinx Coroutines
-dontwarn kotlinx.coroutines.**
-keep class kotlinx.coroutines.** { *; } 