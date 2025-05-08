import 'dart:convert';
import 'dart:typed_data';

import 'package:android_intent_plus/android_intent.dart';
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
      storeId: "store-8d090a12-09b3-4220-8da2-9315e9f47956",
      paymentId: "$paymentId",
      orderName: "주문명",
      totalAmount: 1000,
      currency: "KRW",
      channelKey: "channel-key-64979111-ecd7-4d44-9ba1-093c1de1b8ca",
      payMethod: "CARD",
      redirectUrl: "portone://complete",
    }).catch((err) => window.flutter_inappwebview.callHandler("portoneError", err.message));
  });
</script>
</head>
</html>
''';

    late InAppWebViewController? controller;
    var logs = <String>[];

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('로그 출력'),
                  onPressed: () async {
                    await showDialog(context: context, builder: (builder) {
                      return AlertDialog(
                        title: Text("로그"),
                        content: Text(logs.join("\n\n")),
                        scrollable: true,
                      );
                    });
                  }
                ),
              ),

              Expanded(
                child: InAppWebView(
                  initialSettings: InAppWebViewSettings(
                    useShouldOverrideUrlLoading: true,
                    resourceCustomSchemes: ["intent"],
                  ),
                  onWebViewCreated: (created) {
                    logs.add("webview created");

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
                    await controller.stopLoading();
                    return null;
                    // logs.add("onLoadResourceWithCustomScheme");
                    //
                    // return CustomSchemeResponse(
                    //     contentType: "text/html", data: Uint8List(0));
                  },
                  shouldOverrideUrlLoading: (controller, navigateAction) async {
                    final url = navigateAction.request.url!;
                    final uri = navigateAction.request.url!.rawValue;
                    logs.add("url in shouldOverrideUrlLoading: $uri");
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
                        // try {
                        //   await AndroidIntent(
                        //     action: 'action_view',
                        //     data: uri.toString(),
                        //   ).launch();
                        // } catch (e) {
                        //   logs.add("android intent fail: $e");

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
                          var redirect = '${scheme != null ? '${scheme}:' : ''}${uri.substring(colon + 1, firstHash)}';
                          logs.add("redirect when intent case: $redirect");

                          var canLaunch = await canLaunchUrlString(redirect);

                          logs.add("canLaunch: $canLaunch");

                          if (canLaunch) {
                            launchUrlString(redirect);
                          }
                        // }

                        return NavigationActionPolicy.CANCEL;
                      default:
                        if (await canLaunchUrlString(uri)) {
                          launchUrlString(uri);
                        }
                        return NavigationActionPolicy.CANCEL;
                    }
                  },
                ),
              )
            ],
          )
        ),
      ),
    );
  }
}
