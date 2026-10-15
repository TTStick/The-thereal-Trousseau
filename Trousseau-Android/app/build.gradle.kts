plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    kotlin("plugin.serialization") version "1.9.25"
}

android {
    namespace = "com.ethereal.trousseau"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.ethereal.trousseau"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables { useSupportLibrary = true }

        // Target the architectures a flagship phone actually uses. We drop
        // x86 / x86_64 because emulators can use the arm64-v8a slice via
        // translation, and armv7 is dead on every device launched since
        // 2020. Net effect: roughly a quarter the APK size.
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    // Self-signed keystore committed in this repo so first-time builders
    // can produce a release APK with `./gradlew :app:assembleRelease`
    // without manually generating one. **Not suitable for Play Store
    // distribution** — generate your own before publishing.
    signingConfigs {
        create("release") {
            storeFile = file("release.keystore")
            storePassword = "trousseau"
            keyAlias = "trousseau"
            keyPassword = "trousseau"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.15"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.10.01")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    // Core
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.4")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.4")
    implementation("androidx.activity:activity-compose:1.9.1")

    // Compose
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.foundation:foundation")

    // Navigation
    implementation("androidx.navigation:navigation-compose:2.7.7")

    // Coil for image loading
    implementation("io.coil-kt:coil-compose:2.6.0")

    // DataStore for theme prefs
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    // JSON
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")

    // ML Kit — on-device subject/foreground segmentation (kept as a fallback).
    // The dynamic GMS module only downloads when Play Services can reach the
    // internet; on locked-down devices we fall back to a bundled TFLite model
    // so the app works offline and on any AOSP device.
    implementation("com.google.android.gms:play-services-mlkit-subject-segmentation:16.0.0-beta1")

    // MediaPipe Tasks Vision — runs the bundled selfie_segmentation.tflite
    // (which uses TF-Select ops the bare TFLite runtime can't dispatch).
    // This is the supported entry point for MediaPipe's segmentation
    // models on Android.
    implementation("com.google.mediapipe:tasks-vision:0.10.14")

    // Tests
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")

    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
