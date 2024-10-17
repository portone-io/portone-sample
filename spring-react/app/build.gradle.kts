plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.spring)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.spring.boot)
    alias(libs.plugins.ktlint)
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(platform(libs.spring.boot.dependencies))
    implementation(libs.spring.boot.starter.webflux)
    implementation(libs.portone.server.sdk)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.kotlinx.coroutines.reactor)
    implementation(libs.kotlin.reflect)
}

kotlin {
    jvmToolchain(21)
    compilerOptions {
        progressiveMode = true
        allWarningsAsErrors = true
        freeCompilerArgs.addAll("-Xjsr305=strict")
    }
}
