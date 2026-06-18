allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Pass 16 KB page-size flag to every Android library's CMake build (e.g. libsweph.so).
    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.LibraryExtension> {
            defaultConfig {
                externalNativeBuild {
                    cmake {
                        arguments(
                            "-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON",
                            "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384"
                        )
                    }
                }
            }
        }
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
subprojects {
    project.evaluationDependsOn(":app")
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
