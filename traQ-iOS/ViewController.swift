//
//  ViewController.swift
//  traQ-iOS
//
//  Created by とーふとふ on 2018/06/20.
//  Copyright © 2018年 traP. All rights reserved.
//

import UIKit
import WebKit
import Firebase

class ViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    
    override func viewDidLoad(){
        super.viewDidLoad()

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.applicationNameForUserAgent = "traQ-iOS"
        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView.navigationDelegate = self
        
        let appDelegete = UIApplication.shared.delegate as! AppDelegate
        
        let path = appDelegete.path
        
        var webUrl: URL
        if path != nil {
            webUrl = URL(string: "https://traq-dev.tokyotech.org" + path!)!
        }else {
            webUrl = URL(string: "https://traq-dev.tokyotech.org")!
        }
        let myRequest = URLRequest(url: webUrl)
        webView.load(myRequest)
        
        appDelegete.webView = webView
        
        
        // インスタンスをビューに追加する
        self.view.addSubview(webView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void){
        let url = navigationAction.request.url
        print(url?.host ?? "po")
        if url?.host != "traq-dev.tokyotech.org" {
            decisionHandler(.cancel)
            UIApplication.shared.open(url!)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("読み込み完了")
        InstanceID.instanceID().instanceID(handler: { (result, error) in
            print(result?.token ?? "No Token")
            self.webView.evaluateJavaScript("window.iOSToken = '" + (result?.token ?? "") + "'", completionHandler: nil)
        })
    }
    
//    func addRefreshFcmTokenNotificationObserver() {
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(self.fcmTokenRefreshNotification(_:)),
//            name: .InstanceIDTokenRefresh,
//            object: nil)
//    }
//    
//    @objc func fcmTokenRefreshNotification(_ notification: Notification) {
//
//    }
//    

}

