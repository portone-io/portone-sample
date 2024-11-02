package org.example.request;

public final class WebhookRequest {
    public String type = "";
    public TransactionData data = new TransactionData();

    public static final class TransactionData {
        public String paymentId = "";
    }
}
