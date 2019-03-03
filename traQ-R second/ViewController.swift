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

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    var webView: WKWebView!
    var openKeyboard: Bool! = false
    var host: String = "q.trap.jp"
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        if (Date() < Date.init(timeIntervalSince1970: 1551348000)) {
            host = "traq-dev.tokyotech.org"
        }

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.applicationNameForUserAgent = "traQ-iOS"
        webConfiguration.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: self.view.frame, configuration: webConfiguration)
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        let appDelegete = UIApplication.shared.delegate as! AppDelegate
        
        let path = appDelegete.path
        
        var webUrl: URL
        if path != nil {
            webUrl = URL(string: "https://" + self.host + path!)!
        } else {
            webUrl = URL(string: "https://" + self.host)!
        }
        let myRequest = URLRequest(url: webUrl)
        webView.load(myRequest)
        
        appDelegete.webView = webView
        appDelegete.host = host

        // インスタンスをビューに追加する
        self.view.addSubview(webView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // self.startObserveKeyboardNotification()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void){
        let url = navigationAction.request.url
        print(url?.host ?? "po")
        if url?.host != self.host {
            decisionHandler(.cancel)
            UIApplication.shared.open(url!)
        } else {
            decisionHandler(.allow)
        }
    }
    
    // display alert dialog
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let otherAction = UIAlertAction(title: "OK", style: .default) {
            action in completionHandler()
        }
        alertController.addAction(otherAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // display confirm dialog
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            action in completionHandler(false)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) {
            action in completionHandler(true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // display prompt dialog
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        // variable to keep a reference to UIAlertController
        let alertController = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        
        let okHandler: () -> Void = {
            if let textField = alertController.textFields?.first {
                completionHandler(textField.text)
            } else {
                completionHandler("")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            action in completionHandler("")
        }
        let okAction = UIAlertAction(title: "OK", style: .default) {
            action in okHandler()
        }
        alertController.addTextField() { $0.text = defaultText }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("読み込み完了")
        InstanceID.instanceID().instanceID(handler: { (result, error) in
            print(result?.token ?? "No Token")
            self.webView.evaluateJavaScript("window.iOSToken = '" + (result?.token ?? "") + "'", completionHandler: nil)
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {
            if (self.openKeyboard) {
                return
            }
            // viewDidLayoutSubviewsではSafeAreaの取得ができている
            let topSafeAreaHeight = self.view.safeAreaInsets.top
            let bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
            
            let width:CGFloat = self.view.frame.width
            let height:CGFloat = self.view.frame.height
            webView.frame = CGRect(
                x: 0, y: topSafeAreaHeight,
                width: width, height: height-topSafeAreaHeight-bottomSafeAreaHeight)
        }
    }
}

