plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.localbaskethd"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.localbaskethd"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true

        ndk {
            abiFilters.clear()
            abiFilters += listOf("arm64-v8a")
        }
    }

    // ✅ RELEASE SIGNING CONFIG (FOR CI/CD)
    signingConfigs {
        create("release") {
            storeFile = file("../upload.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    androidResources {
        noCompress += listOf("so")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {

        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // ✅ USE RELEASE SIGNING
            signingConfig = signingConfigs.getByName("release")

            ndk {
                debugSymbolLevel = "FULL"
            }
        }

        getByName("debug") {
            isMinifyEnabled = false

            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}