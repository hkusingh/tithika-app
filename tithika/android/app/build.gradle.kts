import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

android {
    namespace = "app.tithika"
    // permission_handler_android requires compileSdk 37; override Flutter's
    // own default (36) explicitly rather than waiting for a Flutter bump.
    compileSdk = 37
    ndkVersion = "28.2.13676358"  // NDK r27b — required for 16 KB page-size alignment

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildFeatures {
        compose = true
    }

    defaultConfig {
        applicationId = "app.tithika"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // proguard-rules.pro carries the Gson `-keepattributes Signature`
            // rules that flutter_local_notifications needs. Without them R8
            // strips generic signatures and the plugin throws "Missing type
            // parameter" at runtime, breaking notifications in release builds
            // only — which is why this never reproduced on a debug emulator.
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Glance (home-screen widgets)
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.glance:glance-material3:1.1.1")
}
