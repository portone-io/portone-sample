import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    var paymentId = 'payment${DateTime.now().millisecondsSinceEpoch}';
    var html = '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="https://cdn.portone.io/v2/browser-sdk.js"></script>
<script>
  window.addEventListener("flutterInAppWebViewPlatformReady", () => {
    PortOne.requestPayment({
      storeId: "store-00000000-0000-0000-0000-000000000000",
      paymentId: "$paymentId",
      orderName: "주문명",
      totalAmount: 1000,
      currency: "KRW",
      channelKey: "channel-key-00000000-0000-0000-0000-000000000000",
      payMethod: "CARD",
      redirectUrl: "portone://complete",
    }).catch((err) => window.flutter_inappwebview.callHandler("portoneError", err.message));
  });
</script>
</head>
</html>
''';

    late InAppWebViewController? controller;

    return Scaffold(
      body: PopScope(
        canPop: false,
        // 뒤로가기 버튼을 눌렀을 때 이벤트를 웹뷰에 전달합니다.
        onPopInvokedWithResult: (didPop, result) async {
          if (await controller?.canGoBack() == true) {
            await controller?.goBack();
          } else {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              var state = Navigator.of(context);
              if (state.canPop()) state.pop();
            });
          }
        },
        child: SafeArea(
          child: InAppWebView(
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              resourceCustomSchemes: ["intent"],
            ),
            onWebViewCreated: (created) {
              controller = created;
              controller?.addJavaScriptHandler(
                  handlerName: "portoneError",
                  callback: (data) {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("결제 호출 실패"),
                            content: Text(data[0]),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('확인'))
                            ],
                          );
                        });
                  });
              controller?.loadData(
                  data: html,
                  baseUrl:
                      WebUri('https://flutter-sample-content.portone.io/'));
            },
            // 안드로이드에서 intent:// URL로 이동 시 오류가 아닌 빈 페이지 표시
            onLoadResourceWithCustomScheme: (controller, resource) async {
              return CustomSchemeResponse(
                  contentType: "text/html", data: Uint8List(0));
            },
            shouldOverrideUrlLoading: (controller, navigateAction) async {
              final uri = navigateAction.request.url!.rawValue;
              var colon = uri.indexOf(':');
              var protocol = uri.substring(0, colon);
              switch (protocol) {
                case 'http':
                case 'https':
                  return NavigationActionPolicy.ALLOW;
                case 'portone':
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("결제 결과"),
                          content: Text(json.encode(
                              navigateAction.request.url!.queryParameters)),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('확인'))
                          ],
                        );
                      });
                  return NavigationActionPolicy.CANCEL;
                case 'intent':
                  var firstHash = uri.indexOf('#');
                  String? scheme;
                  for (var param in uri.substring(firstHash + 1).split(';')) {
                    var keyValue = param.split('=');
                    switch (keyValue.elementAtOrNull(0)) {
                      case 'scheme':
                        scheme = keyValue[1];
                        break;
                    }
                  }
                  var redirect = '$scheme${uri.substring(colon, firstHash)}';
                  if (await canLaunchUrlString(redirect)) {
                    launchUrlString(redirect);
                  }
                  return NavigationActionPolicy.CANCEL;
                default:
                  if (await canLaunchUrlString(uri)) {
                    launchUrlString(uri);
                  }
                  return NavigationActionPolicy.CANCEL;
              }
            },
          ),
        ),
      ),
    );
  }
}
