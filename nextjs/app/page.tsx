import { GetPaymentError, PaidPayment, PaymentClient, PaymentStatus } from "@portone/server-sdk/payment"
import PaymentForm, { Item } from "./ui/payment-form"

const portone = PaymentClient({ secret: process.env.V2_API_SECRET })

const items = new Map<string, Omit<Item, "id">>([
  [
    "shoes",
    {
      name: "신발",
      price: 1000,
      currency: "KRW",
    },
  ],
])

// 결제는 브라우저에서 진행되기 때문에, 결제 승인 정보와 결제 항목이 일치하는지 확인해야 합니다.
// 포트원의 customData 파라미터에 결제 항목의 id인 item 필드를 지정하고, 서버의 결제 항목 정보와 일치하는지 확인합니다.
function verifyPayment(payment: PaidPayment) {
  if (payment.customData == null) return false
  const customData = JSON.parse(payment.customData)
  const item = items.get(customData.item)
  if (item == null) return false
  return (
    payment.orderName === item.name &&
    payment.amount.total === item.price &&
    (payment.currency as string) === (item.currency as string)
  )
}

// 서버의 결제 데이터베이스를 따라하는 샘플입니다.
// syncPayment 호출시에 포트원의 결제 건을 조회하여 상태를 동기화하고 결제 완료시에 완료 처리를 합니다.
// 브라우저의 결제 완료 호출과 포트원의 웹훅 호출 두 경우에 모두 상태 동기화가 필요합니다.
// 실제 데이터베이스 사용시에는 결제건 단위 락을 잡아 동시성 문제를 피하도록 합니다.
type Payment = {
  status: PaymentStatus
}
const paymentStore = new Map<string, Payment>()
async function syncPayment(paymentId: string) {
  if (!paymentStore.has(paymentId)) {
    paymentStore.set(paymentId, {
      status: "PENDING",
    })
  }
  const payment = paymentStore.get(paymentId)!
  let actualPayment
  try {
    actualPayment = await portone.getPayment({ paymentId })
  } catch (e) {
    if (e instanceof GetPaymentError) return false
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

async function completePayment(paymentId: string) {
  "use server"

  const payment = await syncPayment(paymentId)
  if (!payment)
    return {
      status: "FAILED",
      message: "결제 동기화에 실패했습니다.",
    }
  return {
    status: payment.status,
  }
}

export default function Home() {
  const shoes = items.get("shoes")!
  const item = {
    ...shoes,
    id: "shoes",
    currency: shoes.currency,
  }

  return (
    <PaymentForm
      item={item}
      storeId={process.env.STORE_ID}
      channelKey={process.env.CHANNEL_KEY}
      completePaymentAction={completePayment}
    />
  )
}
