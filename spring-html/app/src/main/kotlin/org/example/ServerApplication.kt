package org.example

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.boot.runApplication

@SpringBootApplication
@EnableConfigurationProperties(PortOneSecretProperties::class)
open class ServerApplication

fun main(args: Array<String>) {
    runApplication<ServerApplication>(*args)
}
