//
//  ContentView.swift
//  KpnTest
//
//  Created by Holden on 11/1/24.
//

import SwiftUI
import WebKit

struct ContentView: View {
    private let controller = WebViewController()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
            Button(action: {
        }){
            Text("V2 SDK결제 테스트")
            
        }
        WebView(controller: controller)
    }
}

#Preview {
    ContentView()
}

struct WebView: UIViewRepresentable {
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
    var webView = WKWebView()
    private let controller: WebViewController
    
    init(controller: WebViewController) {
        self.controller = controller
    }

  
    
    func makeUIView(context: Context) -> WKWebView {
        let webView =  WKWebView()
        webView.navigationDelegate = controller
        webView.loadHTMLString(htmlString, baseURL: URL(string:"https://sdk-playground.portone.io/"))
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {

        
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
