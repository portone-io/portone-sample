import { Payment, PortOneController } from "@portone/react-native-sdk"
import { createRef, useEffect } from "react"
import { BackHandler, View } from "react-native"

export default function App() {
  const controller = createRef<PortOneController>()
  // 뒤로가기 버튼을 눌렀을 때 결제창 내부에서 처리
  useEffect(() => {
    const backHandler = BackHandler.addEventListener(
      "hardwareBackPress",
      () => {
        if (controller.current?.canGoBack) {
          controller.current.webview?.goBack()
          return true
        }
        return false
      },
    )
    return () => backHandler.remove()
  })
  return (
    <View style={{ flex: 1 }}>
      <Payment
        ref={controller}
        request={{
          storeId: "store-00000000-0000-0000-0000-000000000000",
          channelKey: "channel-key-00000000-0000-0000-0000-000000000000",
          paymentId: "test",
          orderName: "주문명",
          totalAmount: 1000,
          currency: "CURRENCY_KRW",
          payMethod: "CARD",
        }}
        onError={(error) => alert(error.message)}
        onComplete={(complete) => alert(JSON.stringify(complete))}
      />
    </View>
  )
}
