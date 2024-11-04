//
//  ViewController.swift
//  uikittest
//
//  Created by Holden on 11/4/24.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate{
    var webView: WKWebView!
    var htmlString: String {
           """
           <!DOCTYPE html>
           <html lang="ko">

           <head>
               <meta charset="UTF-8">
               <meta http-equiv="X-UA-Compatible" content="IE=edge">
               <meta name="viewport" content="width=device-width, initial-scale=1.0">
               <script src="https://cdn.portone.io/v2/browser-sdk.js"></script>
           </head>
           <script>

           function requestPayment(request) {           
                PortOne.requestPayment(JSON.parse(request));
           }
                    
           </script>
           <body>
           </body>

           </html>
           """
       }
    override func viewDidLoad() {
        let webConfiguration = WKWebViewConfiguration()

        webView = WKWebView(frame: self.view.frame, configuration: webConfiguration)
        webView.navigationDelegate = self  // Delegate 설정
        self.view.addSubview(webView)
        webView.loadHTMLString(htmlString, baseURL: URL(string:"https://sdk-playground.portone.io/"))
    }
    
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        decisionHandler(.allow)
    }
    
    private func evaluateRequestPaymentJavascript(with webView: WKWebView) {
        let request = PaymentRequest(
            storeId: "고객사 storeId",
            paymentId: "고객사 paymentId",
            orderName: "테스트 결제",
            totalAmount: 100,
            currency: "KRW",
            channelKey: "고객사 채널 키",
            payMethod:"CARD",
            redirectUrl: "고객사 redirectUrl")
        let requestEncodedJson = try! JSONEncoder().encode(request)
        let requestEncodedString = String(data: requestEncodedJson, encoding: .utf8)
        
        let rawRequest = "requestPayment('\(requestEncodedString!)');"
        DispatchQueue.main.async {
            webView.evaluateJavaScript(rawRequest){
                result, error in
                if let error = error {
                    print("JavaScript evaluation error: \(error)")
                } else {
                    print("JavaScript evaluation result: \(String(describing: result))")
                }
            }
        }
    }
    
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
       self.evaluateRequestPaymentJavascript(with: webView)
    }
}

public struct PaymentRequest: Codable{
    public var storeId: String
    
    public var paymentId: String
    
    public var orderName: String
    
    public var totalAmount: Int
    
    public var currency: String
    
    public var channelKey: String
    
    public var payMethod: String
    
    public var redirectUrl: String
    
    
}
