package org.example.request

class WebhookRequest {
    var type: String = ""
    var data: TransactionData = TransactionData()

    class TransactionData {
        var paymentId: String = ""
    }
}
