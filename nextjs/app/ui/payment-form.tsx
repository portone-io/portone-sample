"use client"

import * as PortOne from "@portone/browser-sdk/v2"
import type { Currency } from "@portone/server-sdk/common"
import Image from "next/image"
import { FormEventHandler, useState } from "react"
import { randomId } from "../lib/random"

export type Item = {
  id: string
  name: string
  price: number
  currency: Currency
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
    setPaymentStatus({
      status: "PENDING",
    })
    const paymentId = randomId()
    const payment = await PortOne.requestPayment({
      storeId,
      channelKey,
      paymentId,
      orderName: item.name,
      totalAmount: item.price,
      currency: item.currency as PortOne.Entity.Currency,
      payMethod: "CARD",
      customData: {
        item: item.id,
      },
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

  const isWaitingPayment = paymentStatus.status !== "IDLE"

  return (
    <>
      <main>
        <form onSubmit={handleSubmit}>
          <article>
            <div className="item">
              <div className="item-image">
                <Image
                  src={`/${item.id}.png`}
                  alt="item"
                  width="66"
                  height="69"
                />
              </div>
              <div className="item-text">
                <h5>{item.name}</h5>
                <p>{item.price.toLocaleString()}원</p>
              </div>
            </div>
            <div className="price">
              <label>총 구입 가격</label>
              {item.price.toLocaleString()}원
            </div>
          </article>
          <button
            type="submit"
            aria-busy={isWaitingPayment}
            disabled={isWaitingPayment}
          >
            결제
          </button>
        </form>
      </main>
      {paymentStatus.status === "FAILED" && (
        <dialog open>
          <header>
            <h1>결제 실패</h1>
          </header>
          <p>{paymentStatus.message}</p>
          <button type="button" onClick={handleClose}>
            닫기
          </button>
        </dialog>
      )}
      <dialog open={paymentStatus.status === "PAID"}>
        <header>
          <h1>결제 성공</h1>
        </header>
        <p>결제에 성공했습니다.</p>
        <button type="button" onClick={handleClose}>
          닫기
        </button>
      </dialog>
      <dialog open={paymentStatus.status === "VIRTUAL_ACCOUNT_ISSUED"}>
        <header>
          <h1>가상계좌 발급 완료</h1>
        </header>
        <p>가상계좌가 발급되었습니다.</p>
        <button type="button" onClick={handleClose}>
          닫기
        </button>
      </dialog>
    </>
  )
}
