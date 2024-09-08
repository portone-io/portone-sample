package org.example

import io.portone.sdk.server.schemas.Currency

data class Item(
    val id: String,
    val name: String,
    val price: Int,
    val currency: Currency,
)
