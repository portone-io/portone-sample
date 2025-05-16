package org.example

import io.portone.sdk.server.common.Currency
import io.portone.sdk.server.payment.PaidPayment
import io.portone.sdk.server.payment.PaymentClient
import io.portone.sdk.server.payment.VirtualAccountIssuedPayment
import io.portone.sdk.server.webhook.WebhookTransaction
import io.portone.sdk.server.webhook.WebhookVerifier
import kotlinx.serialization.json.Json
import org.example.request.CompletePaymentRequest
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RestController

@RestController
class PaymentController(secret: PortOneSecretProperties) {
    companion object {
        private val items: Map<String, Item> =
            mapOf(
                "shoes" to
                    Item(
                        id = "shoes",
                        name = "신발",
                        price = 1000,
                        currency = Currency.Krw.value,
                    ),
            )

        private val paymentStore: MutableMap<String, Payment> = mutableMapOf()
        private val json: Json = Json { ignoreUnknownKeys = true }
        private val logger: Logger = LoggerFactory.getLogger(PaymentController::class.java)
    }

    private val portone = PaymentClient(apiSecret = secret.api)
    private val portoneWebhook = WebhookVerifier(secret.webhook)

    @GetMapping("/api/item")
    fun getItem(): Item {
        return items["shoes"]!!
    }

    // 인증 결제(결제창을 이용한 결제)를 위한 엔드포인트입니다.
    //
    // 브라우저에서 결제 완료 후 서버에 결제 완료를 알리는 용도입니다.
    // 결제 수단 및 PG사 사정에 따라 결제 완료 후 승인이 지연될 수 있으므로
    // 결제 정보를 완전히 실시간으로 얻기 위해서는 웹훅을 사용해야 합니다.
    //
    // 인증 결제 연동 가이드: https://developers.portone.io/docs/ko/authpay/guide?v=v2
    @PostMapping("/api/payment/complete")
    suspend fun completePayment(
        @RequestBody completeRequest: CompletePaymentRequest,
    ): Payment = syncPayment(completeRequest.paymentId)

    // 결제 정보를 실시간으로 전달받기 위한 웹훅입니다.
    // 관리자 콘솔에서 웹훅 정보를 등록해야 사용할 수 있습니다.
    //
    // 웹훅 연동 가이드: https://developers.portone.io/docs/ko/v2-payment/webhook?v=v2
    @PostMapping("/api/payment/webhook")
    suspend fun handleWebhook(
        // 웹훅 검증 시 텍스트로 된 body가 필요합니다.
        @RequestBody body: String,
        @RequestHeader("webhook-id") webhookId: String,
        @RequestHeader("webhook-timestamp") webhookTimestamp: String,
        @RequestHeader("webhook-signature") webhookSignature: String,
    ) {
        val webhook =
            try {
                portoneWebhook.verify(body, webhookId, webhookSignature, webhookTimestamp)
            } catch (_: Exception) {
                throw SyncPaymentException()
            }
        if (webhook is WebhookTransaction) {
            syncPayment(webhook.data.paymentId)
        }
    }

    // 서버의 결제 데이터베이스를 따라하는 샘플입니다.
    // syncPayment 호출시에 포트원의 결제 건을 조회하여 상태를 동기화하고 결제 완료시에 완료 처리를 합니다.
    // 브라우저의 결제 완료 호출과 포트원의 웹훅 호출 두 경우에 모두 상태 동기화가 필요합니다.
    // 실제 데이터베이스 사용시에는 결제건 단위 락을 잡아 동시성 문제를 피하도록 합니다.
    suspend fun syncPayment(paymentId: String): Payment {
        val payment =
            paymentStore.getOrPut(paymentId) {
                Payment("PENDING")
            }
        val actualPayment =
            try {
                portone.getPayment(paymentId = paymentId)
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
                        paymentStore[paymentId] = it
                    }
                }
            }
            is VirtualAccountIssuedPayment ->
                payment.copy(status = "VIRTUAL_ACCOUNT_ISSUED").also {
                    paymentStore[paymentId] = it
                }
            else -> throw SyncPaymentException()
        }
    }

    // 결제는 브라우저에서 진행되기 때문에, 결제 승인 정보와 결제 항목이 일치하는지 확인해야 합니다.
    // 포트원의 customData 파라미터에 결제 항목의 id인 item 필드를 지정하고, 서버의 결제 항목 정보와 일치하는지 확인합니다.
    fun verifyPayment(payment: PaidPayment): Boolean {
        // 실연동 시에 테스트 채널키로 변조되어 결제되지 않도록 검증해야 합니다.
        // if (payment.channel.type != SelectedChannelType.Live) return false
        return payment.customData?.let { customData ->
            items[json.decodeFromString<PaymentCustomData>(customData).item]?.let {
                payment.orderName == it.name &&
                    payment.amount.total == it.price.toLong() &&
                    payment.currency.value == it.currency
            }
        } == true
    }
}
