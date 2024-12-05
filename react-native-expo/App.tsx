import { Payment, PortOneController } from "@portone/react-native-sdk"
import { createRef, useEffect } from "react"
import { Alert, BackHandler, SafeAreaView } from "react-native"

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
  const uid = Date.now().toString(16)
  return (
    <SafeAreaView style={{ flex: 1 }}>
      <Payment
        ref={controller}
        request={{
          storeId: "store-00000000-0000-0000-0000-000000000000",
          channelKey: "channel-key-00000000-0000-0000-0000-000000000000",
          paymentId: uid,
          orderName: "주문명",
          totalAmount: 1000,
          currency: "CURRENCY_KRW",
          payMethod: "CARD",
        }}
        onError={(error) => Alert.alert("실패", error.message)}
        onComplete={(complete) => Alert.alert("완료", JSON.stringify(complete))}
      />
    </SafeAreaView>
  )
}
