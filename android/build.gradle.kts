plugins {
    id("com.android.library")
    id("kotlin-android")
}

group = "ru.pathcreator.smart.video.thumbnails"
version = "0.2.0"

repositories {
    google()
    mavenCentral()
    
    // JitPack - smart-ffmpeg-android (no credentials required!)
    maven {
        url = uri("https://jitpack.io")
    }
}

android {
    namespace = "ru.pathcreator.smart.video.thumbnails.smart_video_thumbnail"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        minSdk = 21
        targetSdk = 34

        // v0.2.0: Optimized for ARM architectures only to reduce APK size
        // Excludes x86 and x86_64 architectures
        // Supported: arm64-v8a (64-bit ARM), armeabi-v7a (32-bit ARM)
        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
        }
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
    
    // Smart FFmpeg Android Library v1.0.4 from JitPack
    implementation("com.github.Daronec:smart-ffmpeg-android:1.0.4")
}
