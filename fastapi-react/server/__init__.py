import json
import os
from dataclasses import dataclass
from typing import Annotated

import portone_server_sdk as portone
from dotenv import load_dotenv
from fastapi import Body, Depends, FastAPI, Request


@dataclass
class Item:
    id: str
    name: str
    price: int
    currency: portone.common.Currency


@dataclass
class Payment:
    status: str


load_dotenv()
app = FastAPI()

items = {item.id: item for item in [Item("shoes", "신발", 1000, "KRW")]}
portone_client = portone.PaymentClient(secret=os.environ["V2_API_SECRET"])


# 결제는 브라우저에서 진행되기 때문에, 결제 승인 정보와 결제 항목이 일치하는지 확인해야 합니다.
# 포트원의 custom_data 파라미터에 결제 항목의 id인 item 필드를 지정하고, 서버의 결제 항목 정보와 일치하는지 확인합니다.
def verify_payment(payment):
    # 실연동 시에 테스트 채널키로 변조되어 결제되지 않도록 검증해야 합니다.
    # if payment.channel.type != "LIVE":
    #     return False
    if payment.custom_data is None:
        return False
    custom_data = json.loads(payment.custom_data)
    if "item" not in custom_data or custom_data["item"] not in items:
        return False
    item = items[custom_data["item"]]
    return (
        payment.order_name == item.name
        and payment.amount.total == item.price
        and payment.currency == item.currency
    )


payment_store = {}


def sync_payment(payment_id):
    if payment_id not in payment_store:
        payment_store[payment_id] = Payment("PENDING")
    payment = payment_store[payment_id]
    try:
        actual_payment = portone_client.get_payment(payment_id=payment_id)
    except portone.payment.GetPaymentError:
        return None
    if isinstance(actual_payment, portone.payment.PaidPayment):
        if not verify_payment(actual_payment):
            return None
        if payment.status == "PAID":
            return payment
        payment.status = "PAID"
        print("결제 성공", actual_payment)
    if isinstance(actual_payment, portone.payment.VirtualAccountIssuedPayment):
        payment.status = "VIRTUAL_ACCOUNT_ISSUED"
    else:
        return None
    return payment


@app.get("/api/item")
def get_item():
    return items["shoes"]


@app.post("/api/payment/complete")
def complete_payment(payment_id: Annotated[str, Body(embed=True, alias="paymentId")]):
    payment = sync_payment(payment_id)
    if payment is None:
        return "결제 동기화에 실패했습니다.", 400
    return payment


async def get_raw_body(request: Request):
    return await request.body()


@app.post("/api/payment/webhook")
def receive_webhook(request: Request, body=Depends(get_raw_body)):
    try:
        webhook = portone.webhook.verify(
            os.environ["V2_WEBHOOK_SECRET"],
            body.decode("utf-8"),
            request.headers,
        )
    except portone.webhook.WebhookVerificationError:
        return "Bad Request", 400
    if not isinstance(webhook, dict) and isinstance(
        webhook.data, portone.webhook.WebhookTransactionData
    ):
        sync_payment(webhook.data.payment_id)
    return "OK", 200
