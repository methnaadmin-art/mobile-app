import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    val hasReleaseKeystore = keystorePropertiesFile.exists()
    if (hasReleaseKeystore) {
        keystoreProperties.load(keystorePropertiesFile.inputStream())
    }
    fun requireKeystoreProperty(name: String): String {
        val value = keystoreProperties.getProperty(name)
            ?: keystoreProperties.getProperty("\uFEFF$name")
        return value?.trim()?.takeIf { it.isNotEmpty() }
            ?: throw GradleException("Missing '$name' in android/key.properties")
    }
    fun resolveKeystoreFile(path: String) =
        rootProject.file(path).takeIf { it.exists() }
            ?: file(path).takeIf { it.exists() }
            ?: throw GradleException(
                "Release keystore file not found. " +
                    "Checked '${rootProject.file(path).absolutePath}' and '${file(path).absolutePath}'."
            )

    val googleWebClientId =
        (project.findProperty("GOOGLE_WEB_CLIENT_ID") as String?)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: System.getenv("GOOGLE_WEB_CLIENT_ID")
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
            ?: "980830018700-cjjk2dk6g53j5a60bd2n0nec3kf4fpq1.apps.googleusercontent.com"

    namespace = "com.methna.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.methna.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // google_sign_in Android fallback reads this resource when explicit
        // serverClientId is not provided by native config tools.
        resValue("string", "default_web_client_id", googleWebClientId)
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = requireKeystoreProperty("keyAlias")
                keyPassword = requireKeystoreProperty("keyPassword")
                storeFile = resolveKeystoreFile(requireKeystoreProperty("storeFile"))
                storePassword = requireKeystoreProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (!hasReleaseKeystore) {
                throw GradleException(
                    "Missing android/key.properties for release signing. " +
                        "Create it from android/key.properties.example before building AAB."
                )
            }
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.android.gms:play-services-base:18.7.2")
}
