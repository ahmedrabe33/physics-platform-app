plugins {
    id("com.android.application")

    // Flutter Gradle Plugin must be applied
    // after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.physics_platform_mobile"

    // Required by flutter_secure_storage
    compileSdk = 37

    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.physics_platform_mobile"

        minSdk = flutter.minSdkVersion

        // We don't need to force targetSdk 37 just
        // because compileSdk is 37.
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Lab configuration only.
            // Later we'll configure a real release keystore.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
