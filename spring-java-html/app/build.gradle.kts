plugins {
    alias(libs.plugins.spring.boot)
    `java-library`
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(platform(libs.spring.boot.dependencies))
    implementation(libs.spring.boot.starter.webflux)
    implementation(libs.portone.server.sdk)
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}
