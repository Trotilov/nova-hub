plugins { id("com.android.application") }

android {
    namespace = "dev.novahub.app"
    compileSdk = 35
    defaultConfig {
        applicationId = "dev.novahub.app"
        minSdk = 26
        targetSdk = 35
        versionCode = 2
        versionName = "0.2.0"
    }
    buildTypes {
        release { isMinifyEnabled = false }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
