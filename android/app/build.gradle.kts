import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

fun readEnvValue(envFile: File, key: String): String? {
    if (!envFile.exists()) return null
    val regex = Regex("""^\s*${Regex.escape(key)}\s*=\s*"?([^"]*)"?\s*$""")
    return envFile.readLines()
        .asSequence()
        .map { it.trim() }
        .firstNotNullOfOrNull { line ->
            if (line.isEmpty() || line.startsWith("#")) return@firstNotNullOfOrNull null
            val match = regex.find(line) ?: return@firstNotNullOfOrNull null
            match.groupValues.getOrNull(1)?.trim()?.takeIf { it.isNotEmpty() }
        }
}

val mapsApiKey =
    System.getenv("GOOGLE_MAPS_API_KEY")
        ?: localProperties.getProperty("GOOGLE_MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: readEnvValue(rootProject.file("../assets/.env"), "GOOGLE_MAPS_API_KEY")
        ?: ""

android {
    namespace = "com.example.getfittoday_mobile"
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
        applicationId = "com.example.getfittoday_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        create("release") {
            // Check if keystore keys are available in env vars
            val isCI = System.getenv("CI") == "true" || System.getenv("BITRISE_IO") == "true"
            
            if (System.getenv("KEY_ALIAS") != null) {
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
                storeFile = file(System.getenv("KEYSTORE_PATH") ?: "release-keystore.jks")
                storePassword = System.getenv("KEY_PASSWORD") 
            } else {
                 // Fallback to debug for now if no keys provided locally, or handle local.properties here
                // For now, mirroring debug config if keys missing to prevent local build failures
                val debugConfig = getByName("debug")
                keyAlias = debugConfig.keyAlias
                keyPassword = debugConfig.keyPassword
                storeFile = debugConfig.storeFile
                storePassword = debugConfig.storePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
