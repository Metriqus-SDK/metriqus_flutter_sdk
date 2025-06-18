# Metriqus Flutter SDK ProGuard Rules

# Keep all Metriqus SDK classes
-keep class com.metriqus.** { *; }
-keepclassmembers class com.metriqus.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keepclassmembers class io.flutter.** { *; }

# Keep device info classes
-keep class io.flutter.plugins.deviceinfo.** { *; }
-keepclassmembers class io.flutter.plugins.deviceinfo.** { *; }

# Keep package info classes
-keep class io.flutter.plugins.packageinfo.** { *; }
-keepclassmembers class io.flutter.plugins.packageinfo.** { *; }

# Keep connectivity classes
-keep class com.baseflow.connectivity.** { *; }
-keepclassmembers class com.baseflow.connectivity.** { *; }

# Keep path provider classes
-keep class io.flutter.plugins.pathprovider.** { *; }
-keepclassmembers class io.flutter.plugins.pathprovider.** { *; }

# Keep shared preferences classes
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }

# Keep HTTP classes
-keep class dart.** { *; }
-keepclassmembers class dart.** { *; }

# Keep crypto classes
-keep class javax.crypto.** { *; }
-keepclassmembers class javax.crypto.** { *; }

# Keep JSON classes
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }

# Keep advertising ID classes
-keep class com.google.android.gms.ads.identifier.** { *; }
-keepclassmembers class com.google.android.gms.ads.identifier.** { *; }

# General Android rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
} 