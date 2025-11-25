plugins {
    id("com.android.application")
    id("kotlin-android") // Kotlin plugin
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
    id("com.google.gms.google-services") // Firebase plugin
}

android {
    namespace = "com.kannada.calculator"
    compileSdk = 36   // Updated for all plugins

    defaultConfig {
        applicationId = "com.kannada.calculator"
        minSdk = flutter.minSdkVersion
        targetSdk = 36   // Updated to match compileSdk
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            isMinifyEnabled = false        // Disable code shrinking
            isShrinkResources = false      // Disable unused resource removal
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Kotlin BOM
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.9.0"))

    // Firebase BoM for compatible versions
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // AdMob (Google Mobile Ads)
    implementation("com.google.android.gms:play-services-ads:22.2.0")
}
