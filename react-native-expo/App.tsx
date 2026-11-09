import { Payment, type PortOneController } from "@portone/react-native-sdk"
import { StatusBar } from "expo-status-bar"
import { useEffect, useRef, useState } from "react"
import { Alert, BackHandler } from "react-native"
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context"

// .env.local에 설정한 값을 사용합니다. (.env 참고)
const STORE_ID = process.env.EXPO_PUBLIC_STORE_ID
const CHANNEL_KEY = process.env.EXPO_PUBLIC_CHANNEL_KEY

export default function App() {
  const controller = useRef<PortOneController>(null)
  // 결제 ID는 결제 시도마다 고유해야 하며, 리렌더링 시 바뀌지 않도록 한 번만 생성합니다.
  const [paymentId] = useState(
    () =>
      `payment-${Date.now().toString(16)}-${Math.random().toString(16).slice(2)}`,
  )

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
  }, [])

  if (!STORE_ID || !CHANNEL_KEY) {
    throw new Error(
      "EXPO_PUBLIC_STORE_ID와 EXPO_PUBLIC_CHANNEL_KEY를 .env.local에 설정해 주세요.",
    )
  }

  return (
    <SafeAreaProvider>
      <StatusBar style="dark" />
      <SafeAreaView style={{ flex: 1 }}>
        <Payment
          ref={controller}
          request={{
            storeId: STORE_ID,
            channelKey: CHANNEL_KEY,
            paymentId,
            orderName: "주문명",
            totalAmount: 1000,
            currency: "CURRENCY_KRW",
            payMethod: "CARD",
          }}
          onError={(error) => Alert.alert("실패", error.message)}
          onComplete={(complete) =>
            Alert.alert("완료", JSON.stringify(complete))
          }
        />
      </SafeAreaView>
    </SafeAreaProvider>
  )
}
