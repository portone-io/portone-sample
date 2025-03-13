import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MaterialApp(home: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    var paymentId = 'payment${DateTime.timestamp().second}';
    var request = '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="https://cdn.portone.io/v2/browser-sdk.js"></script>
<script>
PortOne.requestPayment({
  storeId: 'store-00000000-0000-0000-0000-000000000000',
  paymentId: '$paymentId',
  orderName: '주문명',
  totalAmount: 1000,
  currency: 'KRW',
  channelKey: 'channel-key-00000000-0000-0000-0000-000000000000',
  payMethod: 'CARD',
  redirectUrl: 'portone://complete',
}).catch((err) => webviewChannel.postMessage(err.message))
</script>
</head>
</html>
''';

    var controller = WebViewController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('webviewChannel',
          onMessageReceived: (JavaScriptMessage message) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('결과'),
                content: Text(message.message),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('확인'))
                ],
              );
            });
      })
      ..setNavigationDelegate(NavigationDelegate(onNavigationRequest: (NavigationRequest request) {
        var colon = request.url.indexOf(':');
        var protocol = request.url.substring(0, colon);
        switch (protocol) {
          case 'http':
          case 'https':
            return NavigationDecision.navigate;
          case 'portone':
            var question = request.url.indexOf('?');
            var searchParams = request.url.substring(question);
            controller.runJavaScript(
                'webviewChannel.postMessage(JSON.stringify(Object.fromEntries(new URLSearchParams("$searchParams").entries())));');
            return NavigationDecision.prevent;
          case 'intent':
            var firstHash = request.url.indexOf('#');
            String? scheme;
            for (var param in request.url.substring(firstHash + 1).split(';')) {
              var keyValue = param.split('=');
              switch (keyValue.elementAtOrNull(0)) {
                case 'scheme':
                  scheme = keyValue[1];
                  break;
              }
            }
            var redirect = '$scheme${request.url.substring(colon)}';
            launchUrlString(redirect);
            return NavigationDecision.prevent;
          default:
            launchUrlString(request.url);
            return NavigationDecision.prevent;
        }
      }))
      ..loadHtmlString(request, 'https://flutter-sample-content.portone.io/');

    return Scaffold(
      body: PopScope(
        canPop: false,
        // 뒤로가기 버튼을 눌렀을 때 이벤트를 웹뷰에 전달합니다.
        onPopInvokedWithResult: (didPop, result) async {
          if (await controller.canGoBack()) {
            await controller.goBack();
          } else {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              var state = Navigator.of(context);
              if (state.canPop()) state.pop();
            });
          }
        },
        child: SafeArea(
          child: WebViewWidget(controller: controller),
        ),
      ),
    );
  }
}
