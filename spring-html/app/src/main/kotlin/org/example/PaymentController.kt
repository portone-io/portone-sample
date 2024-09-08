package org.example

import io.portone.sdk.server.schemas.Currency
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RestController

@RestController
class PaymentController {
    companion object {
        private val items: Map<String, Item> = mapOf(
            "item-a" to Item(
                id = "item-a",
                name = "품목 A",
                price = 39900,
                currency = Currency.KRW,
            )
        )

        private val paymentStore: MutableMap<String, Payment> = mutableMapOf()
    }


    @GetMapping("/api/item")
    fun getItem(): Item {
        return items["item-a"]!!
    }

    @PostMapping("/api/payment/complete")
    fun completePayment() {

    }

}
