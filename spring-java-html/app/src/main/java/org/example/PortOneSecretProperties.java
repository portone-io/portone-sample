package org.example;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("portone.secret")
public record PortOneSecretProperties(String api, String webhook) {
}
