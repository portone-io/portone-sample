package org.example;

import io.portone.sdk.server.common.Currency;

public record Item(
        String id,
        String name,
        int price,
        Currency currency
) {
}
