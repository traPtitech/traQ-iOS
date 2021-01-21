//
//  WebView.swift
//  traQ
//
//  Created by spa on 2021/01/21.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    @Binding var url: URL?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.applicationNameForUserAgent = traQConstants.userAgent
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = url else {
            return
        }
        uiView.load(URLRequest(url: url))
    }
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        let url = State(initialValue: traQConstants.defaultUrl as URL?)
        WebView(url: url.projectedValue)
    }
}
