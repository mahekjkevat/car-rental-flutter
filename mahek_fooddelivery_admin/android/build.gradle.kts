
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.4.0") // Use your Android Gradle plugin version
        classpath("com.google.gms:google-services:4.4.2") // Google Services plugin
    }
}

val customBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()

// Assign root build directory as File
rootProject.buildDir = customBuildDir.asFile

// Set subproject build directories
subprojects {
    buildDir = customBuildDir.dir(project.name).asFile
    evaluationDependsOn(":app")
}

// Register clean task if you want
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}