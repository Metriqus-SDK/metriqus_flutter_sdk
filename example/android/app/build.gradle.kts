plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Function to read bundle ID from pubspec.yaml
fun getFlutterBundleId(): String {
    val pubspecFile = file("../../pubspec.yaml")
    if (pubspecFile.exists()) {
        val pubspecContent = pubspecFile.readText()
        val regex = """flutter_app_bundle_id:\s*(.+)""".toRegex()
        val matchResult = regex.find(pubspecContent)
        if (matchResult != null) {
            return matchResult.groupValues[1].trim()
        }
    }
    // Fallback value
    return "com.metriqus.flutter_example"
}

android {
    namespace = getFlutterBundleId()
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID automatically read from pubspec.yaml
        applicationId = getFlutterBundleId()
        // Other values automatically read from pubspec.yaml
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
