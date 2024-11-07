import { Payment } from "@portone/react-native-sdk"
import { View } from "react-native"

export default function App() {
  return (
    <View style={{ flex: 1 }}>
      <Payment
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
