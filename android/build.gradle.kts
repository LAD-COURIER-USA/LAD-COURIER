plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🛡️ REGLA SOBERANA LAD V8 (ALINEACIÓN ATÓMICA):
// Obligamos a que CADA pieza del rompecabezas use Java 17 tanto en Java como en Kotlin.
subprojects {
    afterEvaluate {
        val extension = extensions.findByName("android")
        if (extension is com.android.build.gradle.BaseExtension) {
            extension.compileSdkVersion(36)
            
            // ☕ Sincronización Java
            extension.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        
        // ❄️ Sincronización Kotlin (Evita el error de Inconsistent JVM-target)
        tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            kotlinOptions {
                jvmTarget = "17"
                freeCompilerArgs = freeCompilerArgs + listOf(
                    "-Xskip-metadata-version-check",
                    "-Xskip-prerelease-check",
                    "-Xallow-unstable-dependencies"
                )
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
