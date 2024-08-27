import PortOne from "@portone/browser-sdk/v2"
import { useEffect, useState } from "react"

import { randomId } from "./lib/random"

const { VITE_STORE_ID, VITE_CHANNEL_KEY } = import.meta.env

export function App() {
  const [item, setItem] = useState(null)
  const [isWaitingPayment, setWaitingPayment] = useState(false)
  const [paymentStatus, setPaymentStatus] = useState({
    status: "IDLE",
  })

  useEffect(() => {
    async function loadItem() {
      const response = await fetch("/api/item")
      setItem(await response.json())
    }

    loadItem().catch((error) => console.error(error))
  }, [])

  if (item == null) {
    return (
      <dialog open>
        <article aria-busy>결제 정보를 불러오는 중입니다.</article>
      </dialog>
    )
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const formData = new FormData(e.target)
    setWaitingPayment(true)
    const payMethod = formData.get("method")
    const additionalParams = {}
    switch (payMethod) {
      case "VIRTUAL_ACCOUNT":
        additionalParams.virtualAccount = {
          accountExpiry: {
            validHours: 1, // 1시간
          },
        }
        break
    }
    const paymentId = randomId()
    const payment = await PortOne.requestPayment({
      storeId: VITE_STORE_ID,
      channelKey: VITE_CHANNEL_KEY,
      paymentId,
      orderName: item.name,
      totalAmount: item.price,
      currency: item.currency,
      payMethod: payMethod,
      customData: {
        item: item.id,
      },
      ...additionalParams,
    })
    if (payment.code != null) {
      setWaitingPayment(false)
      setPaymentStatus({
        status: "FAILED",
        message: payment.message,
      })
      return
    }
    const completeResponse = await fetch("/api/payment/complete", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        paymentId: payment.paymentId,
      }),
    })
    setWaitingPayment(false)
    if (completeResponse.ok) {
      const paymentComplete = await completeResponse.json()
      setPaymentStatus({
        status: paymentComplete.status,
      })
    } else {
      setPaymentStatus({
        status: "FAILED",
        message: await completeResponse.text(),
      })
    }
  }

  const handleClose = () =>
    setPaymentStatus({
      status: "IDLE",
    })

  return (
    <>
      <dialog open>
        <article>
          <header>
            <h1>{item.name}</h1>
          </header>
          <form onSubmit={handleSubmit}>
            <label>
              <h4>결제 금액</h4>
              <p>{item.price}원</p>
            </label>
            <label>
              <h4>결제 수단</h4>
              <select name="method">
                <option value="CARD">카드</option>
                <option value="VIRTUAL_ACCOUNT">가상계좌</option>
              </select>
            </label>
            <button
              type="submit"
              aria-busy={isWaitingPayment}
              disabled={isWaitingPayment}
            >
              결제
            </button>
          </form>
        </article>
      </dialog>
      {paymentStatus.status === "FAILED" && (
        <dialog open>
          <article>
            <header>
              <h1>결제 실패</h1>
            </header>
            <p>{paymentStatus.message}</p>
            <button type="button" onClick={handleClose}>
              닫기
            </button>
          </article>
        </dialog>
      )}
      <dialog open={paymentStatus.status === "PAID"}>
        <article>
          <header>
            <h1>결제 성공</h1>
          </header>
          <p>결제에 성공했습니다.</p>
          <button type="button" onClick={handleClose}>
            닫기
          </button>
        </article>
      </dialog>
      <dialog open={paymentStatus.status === "VIRTUAL_ACCOUNT_ISSUED"}>
        <article>
          <header>
            <h1>가상계좌 발급 완료</h1>
          </header>
          <p>결제를 위한 가상계좌를 발급했습니다.</p>
          <button type="button" onClick={handleClose}>
            닫기
          </button>
        </article>
      </dialog>
    </>
  )
}
