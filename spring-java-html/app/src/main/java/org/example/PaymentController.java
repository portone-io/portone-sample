package org.example;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.portone.sdk.server.PortOneClient;
import io.portone.sdk.server.common.Currency;
import io.portone.sdk.server.payment.PaidPayment;
import io.portone.sdk.server.payment.VirtualAccountIssuedPayment;
import io.portone.sdk.server.webhook.WebhookVerifier;
import kotlin.Unit;
import org.example.request.CompletePaymentRequest;
import org.example.request.WebhookRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.HashMap;
import java.util.Map;

@RestController
public final class PaymentController {
    private static final Map<String, Item> items = Map.of("shoes", new Item("shoes", "나이키 멘즈 조이라이드 플라이니트", 1000, Currency.KRW));

    private static final Map<String, Payment> paymentStore = new HashMap<>();
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final Logger logger = LoggerFactory.getLogger(PaymentController.class);

    private final PortOneSecretProperties secret;
    private final PortOneClient portone;
    private final WebhookVerifier portoneWebhook;

    public PaymentController(PortOneSecretProperties secret) {
        this.secret = secret;
        portone = new PortOneClient(secret.api(), null, "https://api.portone.io");
        portoneWebhook = new WebhookVerifier(secret.webhook());
    }

    @GetMapping("/api/item")
    public Item getItem() {
        return items.get("shoes");
    }

    // 인증 결제(결제창을 이용한 결제)를 위한 엔드포인트입니다.
    //
    // 브라우저에서 결제 완료 후 서버에 결제 완료를 알리는 용도입니다.
    // 결제 수단 및 PG사 사정에 따라 결제 완료 후 승인이 지연될 수 있으므로
    // 결제 정보를 완전히 실시간으로 얻기 위해서는 웹훅을 사용해야 합니다.
    //
    // 인증 결제 연동 가이드: https://developers.portone.io/docs/ko/authpay/guide?v=v2
    @PostMapping("/api/payment/complete")
    public Mono<Payment> completePayment(
            @RequestBody CompletePaymentRequest completeRequest
    ) {
        return syncPayment(completeRequest.paymentId);
    }

    // 결제 정보를 실시간으로 전달받기 위한 웹훅입니다.
    // 관리자 콘솔에서 웹훅 정보를 등록해야 사용할 수 있습니다.
    //
    // 웹훅 연동 가이드: https://developers.portone.io/docs/ko/v2-payment/webhook?v=v2
    @PostMapping("/api/payment/webhook")
    public Mono<Unit> handleWebhook(
            // 웹훅 검증 시 텍스트로 된 body가 필요합니다.
            @RequestBody String body,
            @RequestHeader("webhook-id") String webhookId,
            @RequestHeader("webhook-timestamp") String webhookTimestamp,
            @RequestHeader("webhook-signature") String webhookSignature
            ) throws SyncPaymentException {
        WebhookRequest webhook;
        try {
            portoneWebhook.verify(body, webhookId, webhookTimestamp, webhookSignature);
            webhook = objectMapper.readValue(body, WebhookRequest.class);
        } catch (Exception e) {
            throw new SyncPaymentException();
        }
        if (webhook.type.startsWith("Transaction.")) {
            return syncPayment(webhook.data.paymentId).map(payment -> Unit.INSTANCE);
        }
    }

    // 서버의 결제 데이터베이스를 따라하는 샘플입니다.
    // syncPayment 호출시에 포트원의 결제 건을 조회하여 상태를 동기화하고 결제 완료시에 완료 처리를 합니다.
    // 브라우저의 결제 완료 호출과 포트원의 웹훅 호출 두 경우에 모두 상태 동기화가 필요합니다.
    // 실제 데이터베이스 사용시에는 결제건 단위 락을 잡아 동시성 문제를 피하도록 합니다.
    private Mono<Payment> syncPayment(String paymentId) {
        Payment payment = paymentStore.get(paymentId);
        if (payment == null) {
            payment = new Payment("PENDING");
            paymentStore.put(paymentId, payment);
        }
        io.portone.sdk.server.payment.Payment actualPayment;
        try {
            actualPayment = Mono.fromFuture(portone.getPayment().getPayment(paymentId));
        } catch (Exception ignored) {
            throw new SyncPaymentException();
        }
        if (actualPayment instanceof PaidPayment) {
            if (!verifyPayment(actualPayment)) throw SyncPaymentException()
            logger.info("결제 성공 {}", actualPayment)
            if (payment.status == "PAID") {
                payment
            } else {
                payment.copy(status = "PAID").also {
                    paymentStore.put(paymentId, it)
                }
            }
        } else if (actualPayment instanceof VirtualAccountIssuedPayment) {
            payment.copy(status = "VIRTUAL_ACCOUNT_ISSUED").also {
                paymentStore.put(paymentId, it)
            }
        }
    }

    // 결제는 브라우저에서 진행되기 때문에, 결제 승인 정보와 결제 항목이 일치하는지 확인해야 합니다.
    // 포트원의 customData 파라미터에 결제 항목의 id인 item 필드를 지정하고, 서버의 결제 항목 정보와 일치하는지 확인합니다.
    public boolean verifyPayment(io.portone.sdk.server.payment.Payment payment) {
        var customData = payment.getCustomData();
        if (customData == null) return false;

        PaymentCustomData customDataDecoded;
        try {
            customDataDecoded = objectMapper.readValue(customData, PaymentCustomData.class);
        } catch (JsonProcessingException e) {
            return false;
        }

        var item = items.get(customDataDecoded.item());
        if (item == null) return false;

        return payment.getOrderName().equals(item.name()) &&
                payment.getAmount().getTotal() == item.price() &&
                payment.getCurrency() == item.currency();
    }
}
