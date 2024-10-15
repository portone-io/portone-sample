package org.example

import io.portone.sdk.server.PortOneClient
import io.portone.sdk.server.common.Currency
import io.portone.sdk.server.payment.PaidPayment
import io.portone.sdk.server.payment.VirtualAccountIssuedPayment
import io.portone.sdk.server.webhook.WebhookVerifier
import kotlinx.serialization.json.Json
import org.example.request.CompletePaymentRequest
import org.example.request.WebhookRequest
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RestController

@RestController
class PaymentController(private val secret: PortOneSecretProperties) {
    companion object {
        private val items: Map<String, Item> =
            mapOf(
                "item-a" to
                    Item(
                        id = "item-a",
                        name = "품목 A",
                        price = 39900,
                        currency = Currency.KRW,
                    ),
            )

        private val paymentStore: MutableMap<String, Payment> = mutableMapOf()
        private val json: Json = Json.Default
        private val logger: Logger = LoggerFactory.getLogger(PaymentController::class.java)
    }

    private val portone = PortOneClient(secret.api)
    private val portoneWebhook = WebhookVerifier(secret.webhook)

    @GetMapping("/api/item")
    fun getItem(): Item {
        return items["item-a"]!!
    }

    @PostMapping("/api/payment/complete")
    suspend fun completePayment(
        @RequestBody completeRequest: CompletePaymentRequest,
    ): Payment = syncPayment(completeRequest.paymentId)

    @PostMapping("/api/payment/webhook")
    suspend fun handleWebhook(
        @RequestBody body: String,
        @RequestHeader("webhook-id") webhookId: String,
        @RequestHeader("webhook-timestamp") webhookTimestamp: String,
        @RequestHeader("webhook-signature") webhookSignature: String,
    ) {
        val webhook =
            try {
                portoneWebhook.verify(body, webhookId, webhookTimestamp, webhookSignature)
                json.decodeFromString<WebhookRequest>(body)
            } catch (_: Exception) {
                throw SyncPaymentException()
            }
        if (webhook.type.startsWith("Transaction.")) {
            syncPayment(webhook.data.paymentId)
        }
    }

    suspend fun syncPayment(paymentId: String): Payment {
        val payment =
            paymentStore.getOrPut(paymentId) {
                Payment("PENDING")
            }
        val actualPayment =
            try {
                portone.payment.getPayment(paymentId)
            } catch (_: Exception) {
                throw SyncPaymentException()
            }
        return when (actualPayment) {
            is PaidPayment -> {
                if (!verifyPayment(actualPayment)) throw SyncPaymentException()
                logger.info("결제 성공 {}", actualPayment)
                if (payment.status == "PAID") {
                    payment
                } else {
                    payment.copy(status = "PAID").also {
                        paymentStore.put(paymentId, it)
                    }
                }
            }
            is VirtualAccountIssuedPayment ->
                payment.copy(status = "VIRTUAL_ACCOUNT_ISSUED").also {
                    paymentStore.put(paymentId, it)
                }
            else -> throw SyncPaymentException()
        }
    }

    fun verifyPayment(payment: io.portone.sdk.server.payment.Payment): Boolean =
        payment.customData?.let {
            items[json.decodeFromString<PaymentCustomData>(it).item]?.let {
                payment.orderName == it.name &&
                    payment.amount.total == it.price.toLong() &&
                    payment.currency == it.currency
            }
        } == true
}
