//
//  WebViewController.swift
//  KpnTest
//
//  Created by Holden on 11/4/24.
//
import SwiftUI
import WebKit

class WebViewController: NSObject, WKNavigationDelegate{
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
            payMethod: "CARD",
            redirectUrl: "고객사 url")
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
        if webView.url?.absoluteString == "고객사 url" {
            self.evaluateRequestPaymentJavascript(with: webView)
        }
    }
    
    
    
}

