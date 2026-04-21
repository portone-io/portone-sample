import 'package:flutter/material.dart';
import 'package:portone_flutter/v2/portone_payment.dart';
import 'package:portone_flutter/v2/model/request/payment_request.dart';
import 'package:portone_flutter/v2/model/response/payment_response.dart';
import 'package:portone_flutter/v2/model/entity/payment_pay_method.dart';
import 'package:portone_flutter/v2/model/entity/currency.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('포트원 V2 결제 샘플')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const PaymentPage()),
            );
          },
          child: const Text('결제하기', style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PortonePayment(
      appBar: AppBar(title: const Text('포트원 V2 결제')),
      initialChild: const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Padding(padding: EdgeInsets.symmetric(vertical: 15)),
              Text('잠시만 기다려주세요...', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
      data: PaymentRequest(
        storeId: 'store-00000000-0000-0000-0000-000000000000',
        channelKey: 'channel-key-00000000-0000-0000-0000-000000000000',
        payMethod: PaymentPayMethod.CARD,
        orderName: '주문명',
        totalAmount: 1000,
        currency: Currency.KRW,
        paymentId: 'payment_${DateTime.now().millisecondsSinceEpoch}',
        appScheme: 'portone',
      ),
      callback: (PaymentResponse response) {
        bool isSuccess = response.code == null;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                ResultPage(isSuccess: isSuccess, response: response),
          ),
        );
      },
    );
  }
}

class ResultPage extends StatelessWidget {
  final bool isSuccess;
  final PaymentResponse response;

  const ResultPage({
    super.key,
    required this.isSuccess,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('결제 결과')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess
                    ? const Color(0xff52c41a)
                    : const Color(0xfff5222d),
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                isSuccess ? '결제에 성공하였습니다' : '결제에 실패하였습니다',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                child: Column(
                  children: [
                    _buildRow('paymentId', response.paymentId),
                    _buildRow('txId', response.txId),
                    if (!isSuccess) ...[
                      _buildRow('에러 코드', response.code ?? '-'),
                      _buildRow('에러 메시지', response.message ?? '-'),
                    ],
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainApp()),
                    (route) => false,
                  );
                },
                child: const Text('돌아가기', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(flex: 5, child: Text(value)),
        ],
      ),
    );
  }
}
