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
            // Read from Environment Variables (CI) or local.properties (Local)
            val keystoreFile = System.getenv("KEY_PATH") 
                ?: localProperties.getProperty("storeFile")
            
            if (keystoreFile != null) {
                storeFile = file(keystoreFile)
                storePassword = System.getenv("KEY_PASSWORD") ?: localProperties.getProperty("storePassword")
                keyPassword = System.getenv("KEY_PASSWORD") ?: localProperties.getProperty("keyPassword")
                keyAlias = System.getenv("KEY_ALIAS") ?: localProperties.getProperty("keyAlias") ?: "release"
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
