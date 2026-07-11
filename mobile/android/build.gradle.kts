import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 일부 서드파티 플러그인(receive_sharing_intent 1.8.x, flutter_naver_map 등)은 JVM 타깃을
// 명시하지 않아, JDK 21 환경에서 Java 컴파일(기본 1.8)과 Kotlin 컴파일(21) 타깃이 어긋나
// 빌드가 실패한다. 모든 서브프로젝트의 Java·Kotlin 컴파일 타깃을 앱과 동일한 17로 통일한다.
subprojects {
    // Java 측: 태스크에 직접 넣으면 AGP가 android.compileOptions로 다시 덮어쓰므로
    //          권위 있는 소스인 android 확장의 compileOptions를 평가 완료 후 설정한다.
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
    // Kotlin 측: 컴파일 태스크의 jvmTarget을 17로 고정한다.
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
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
