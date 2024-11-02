package org.example

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties("portone.secret")
data class PortOneSecretProperties(val api: String, val webhook: String)
