import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") apply false
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

fun googleMapsApiKey(): String {
    return project.findProperty("GOOGLE_MAPS_API_KEY")?.toString()
        ?: project.findProperty("googleMapsApiKey")?.toString()
        ?: localProperties.getProperty("GOOGLE_MAPS_API_KEY")
        ?: localProperties.getProperty("googleMapsApiKey")
        ?: System.getenv("GOOGLE_MAPS_API_KEY")
        ?: System.getenv("googleMapsApiKey")
        ?: ""
}

android {
    namespace = "com.kintsugi.amica"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        val mapsApiKey = googleMapsApiKey()

        applicationId = "com.kintsugi.amica"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = mapsApiKey

        if (mapsApiKey.isBlank()) {
            logger.lifecycle(
                "GOOGLE_MAPS_API_KEY is not configured; Google Maps will not render on device."
            )
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle(
        "android/app/google-services.json not found; skipping Google Services plugin for CI/debug builds."
    )
}
