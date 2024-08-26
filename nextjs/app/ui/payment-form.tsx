"use client"

import * as PortOne from "@portone/browser-sdk/v2"
import { FormEventHandler, useState } from "react"
import { randomId } from "../lib/random"

export type Item = {
  id: string
  name: string
  price: number
  currency: PortOne.Entity.Currency
}

export type PaymentFormProps = {
  item: Item
  storeId: string
  channelKey: string
  completePaymentAction: (paymentId: string) => Promise<PaymentStatus>
}

export type PaymentStatus = {
  status: string
  message?: string
}

export default function PaymentForm({
  item,
  storeId,
  channelKey,
  completePaymentAction,
}: PaymentFormProps) {
  const [paymentStatus, setPaymentStatus] = useState<PaymentStatus>({
    status: "IDLE",
  })
  const handleClose = () =>
    setPaymentStatus({
      status: "IDLE",
    })
  const handleSubmit: FormEventHandler<HTMLFormElement> = async (e) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    setPaymentStatus({
      status: "PENDING",
    })
    const payMethod = formData.get("method")
    const additionalParams = {}
    switch (payMethod) {
      case "VIRTUAL_ACCOUNT":
        Object.assign(additionalParams, {
          virtualAccount: {
            accountExpiry: {
              validHours: 1, // 1시간
            },
          },
        })
        break
    }
    const paymentId = randomId()
    const payment = await PortOne.requestPayment({
      storeId,
      channelKey,
      paymentId,
      orderName: item.name,
      totalAmount: item.price,
      currency: item.currency,
      payMethod: payMethod as PortOne.Entity.PayMethod,
      customData: {
        item: item.id,
      },
      ...additionalParams,
    })
    if (payment == null || payment?.code != null) {
      setPaymentStatus({
        status: "FAILED",
        message: payment?.message,
      })
      return
    }
    setPaymentStatus(await completePaymentAction(paymentId))
  }
  return (
    <>
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
          aria-busy={paymentStatus.status === "PENDING"}
          disabled={paymentStatus.status === "PENDING"}
        >
          결제
        </button>
      </form>
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
