package org.example;

public record Item(
        String id,
        String name,
        int price,
        String currency
) {
}
