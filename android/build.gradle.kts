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
subprojects {
    project.evaluationDependsOn(":app")
}

// blue_thermal_printer (last published 2023) predates AGP's mandatory
// `namespace` requirement (AGP 7+). Inject it here rather than patching the
// package in pub-cache, since that gets wiped on every `pub get`.
subprojects {
    if (project.name == "blue_thermal_printer") {
        afterEvaluate {
            extensions.findByName("android")?.withGroovyBuilder {
                setProperty("namespace", "id.kakzaki.blue_thermal_printer")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
