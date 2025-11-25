plugins {
    id("com.android.application") version "8.9.1" apply false
    id("com.google.gms.google-services") version "4.4.3" apply false
    // ⚠ Flutter plugin removed from root-level
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
