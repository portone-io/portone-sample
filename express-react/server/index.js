const express = require("express")
const bodyParser = require("body-parser")
const PortOne = require("@portone/server-sdk")

const portOne = PortOne.PortOneApi(process.env.V2_API_SECRET)

// 결제는 브라우저에서 진행되기 때문에, 결제 승인 정보와 결제 항목이 일치하는지 확인해야 합니다.
// 포트원의 customData 파라미터에 결제 항목의 id인 item 필드를 지정하고, 서버의 결제 항목 정보와 일치하는지 확인합니다.
function verifyPayment(payment) {
  const customData = JSON.parse(payment.customData)
  const item = items.get(customData.item)
  if (item == null) return false
  const paymentItem = {
    name: payment.orderName,
    price: payment.amount.total,
    currency: payment.currency,
  }
  for (const [key, value] of Object.entries(paymentItem))
    if (item[key] !== value) return false
  return true
}

// 서버의 결제 데이터베이스를 따라하는 샘플입니다.
// syncPayment 호출시에 포트원의 결제 건을 조회하여 상태를 동기화하고 결제 완료시에 완료 처리를 합니다.
// 브라우저의 결제 완료 호출과 포트원의 웹훅 호출 두 경우에 모두 상태 동기화가 필요합니다.
// 실제 데이터베이스 사용시에는 결제건 단위 락을 잡아 동시성 문제를 피하도록 합니다.
const paymentStore = new Map()
async function syncPayment(paymentId) {
  if (!paymentStore.has(paymentId)) {
    paymentStore.set(paymentId, {
      status: "PENDING",
    })
  }
  const payment = paymentStore.get(paymentId)
  let actualPayment
  try {
    actualPayment = await portOne.getPayment(paymentId)
  } catch (e) {
    if (e instanceof PortOne.Errors.PortOneError) return false
    throw e
  }
  switch (actualPayment.status) {
    case "PAID":
      if (!verifyPayment(actualPayment)) return false
      if (payment.status === "PAID") return payment
      payment.status = "PAID"
      console.info("결제 성공", actualPayment)
      break
    case "VIRTUAL_ACCOUNT_ISSUED":
      payment.status = "VIRTUAL_ACCOUNT_ISSUED"
      break
    default:
      return false
  }
  return payment
}

const app = express()

// 웹훅 검증 시 텍스트로 된 body가 필요하기 때문에, bodyParser.json보다 먼저 호출해야 합니다.
app.use(
  "/api/payment/webhook",
  bodyParser.text({
    type: "application/json",
  }),
)
app.use(bodyParser.json())

const items = new Map([
  [
    "item-a",
    {
      name: "품목 A",
      price: 39900,
      currency: "KRW",
    },
  ],
])

app.get("/api/item", (req, res) => {
  const id = "item-a"
  res.json({
    id,
    ...items.get(id),
  })
})

// 인증 결제(결제창을 이용한 결제)를 위한 엔드포인트입니다.
//
// 브라우저에서 결제 완료 후 서버에 결제 완료를 알리는 용도입니다.
// 결제 수단 및 PG사 사정에 따라 결제 완료 후 승인이 지연될 수 있으므로
// 결제 정보를 완전히 실시간으로 얻기 위해서는 웹훅을 사용해야 합니다.
//
// 인증 결제 연동 가이드: https://developers.portone.io/docs/ko/authpay/guide?v=v2
app.post("/api/payment/complete", async (req, res, next) => {
  try {
    const { paymentId } = req.body
    if (typeof paymentId !== "string")
      return res.status(400).send("올바르지 않은 요청입니다.").end()
    const payment = await syncPayment(paymentId)
    if (!payment) return res.status(400).send("결제 동기화에 실패했습니다.")
    switch (payment.status) {
      case "PAID":
        res.status(200).json({
          status: "PAID",
        })
        break
      case "VIRTUAL_ACCOUNT_ISSUED":
        res.status(200).json({
          status: "VIRTUAL_ACCOUNT_ISSUED",
        })
        break
    }
  } catch (e) {
    next(e)
  }
})

// 결제 정보를 실시간으로 전달받기 위한 웹훅입니다.
// 관리자 콘솔에서 웹훅 정보를 등록해야 사용할 수 있습니다.
//
// 웹훅 연동 가이드: https://developers.portone.io/docs/ko/v2-payment/webhook?v=v2
app.post("/api/payment/webhook", async (req, res, next) => {
  try {
    try {
      await PortOne.Webhook.verify(
        process.env.V2_WEBHOOK_SECRET,
        req.body,
        req.headers,
      )
    } catch (e) {
      if (e instanceof PortOne.Webhook.WebhookVerificationError)
        return res.status(400).end()
      throw e
    }
    const {
      type,
      data: { paymentId },
    } = JSON.parse(req.body)
    if (type.startsWith("Transaction.")) await syncPayment(paymentId)
    res.status(200).end()
  } catch (e) {
    next(e)
  }
})

const server = app.listen(8080, "localhost", () => {
  console.log("server is running on", server.address())
})
