const express = require("express")
const bodyParser = require("body-parser")
const PortOne = require("@portone/server-sdk")

const app = express()
const portOne = PortOne.PortOneApi(process.env.V2_API_SECRET)

app.use(
  "/payment/webhook",
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

app.get("/item", (req, res) => {
  const id = "item-a"
  res.json({
    id,
    ...items.get(id),
  })
})

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

const paymentRegistry = new Map()
async function syncPayment(paymentId) {
  if (!paymentRegistry.has(paymentId)) {
    paymentRegistry.set(paymentId, {
      status: "PENDING",
    })
  }
  const payment = paymentRegistry.get(paymentId)
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

app.post("/payment/complete", async (req, res, next) => {
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

app.post("/payment/webhook", async (req, res, next) => {
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
