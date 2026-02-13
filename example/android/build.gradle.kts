allprojects {
    repositories {
        google()
        mavenCentral()
        
        // JitPack - smart-ffmpeg-android (no credentials required!)
        maven {
            url = uri("https://jitpack.io")
        }
    }
}

rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
