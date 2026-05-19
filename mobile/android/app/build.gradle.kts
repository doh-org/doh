import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.doh.memotrip"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.doh.memotrip"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // --dart-define 값을 AndroidManifest ${} 변수로 주입
        val dartDefines = project.findProperty("dart-defines") as String? ?: ""
        if (dartDefines.isNotEmpty()) {
            dartDefines.split(",").forEach { entry ->
                val decoded = String(Base64.getDecoder().decode(entry))
                val kv = decoded.split("=", limit = 2)
                if (kv.size == 2) manifestPlaceholders[kv[0]] = kv[1]
            }
        }
    }

    buildTypes {
        debug {
            // 개발 중 필터 불필요 — Flutter가 연결 기기(ARM) 맞춰 빌드
            // ndk { abiFilters += listOf("arm64-v8a") }
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
            // 배포 전 활성화 — 실기기(ARM) 타깃, x86(에뮬레이터) 제외
            // ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a") }
        }
    }
}

flutter {
    source = "../.."
}
