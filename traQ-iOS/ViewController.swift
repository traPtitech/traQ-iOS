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
        // webView = WKWebView(frame: self.view.frame, configuration: webConfiguration)
        webView = WKWebView()
        webView.configuration.applicationNameForUserAgent = "traQ-iOS"
        webView.navigationDelegate = self
        
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

extension ViewController {
    /** キーボードのNotificationを購読開始 */
    func startObserveKeyboardNotification(){
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(willShowKeyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(willHideKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    /** キーボードのNotificationの購読停止 */
    func stopOberveKeyboardNotification(){
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    /** キーボードが開いたときに呼び出されるメソッド */
    @objc func willShowKeyboard(_ notification:NSNotification){
        NSLog("willShowKeyboard called.")
        let rect     = notification.rect()
        // viewDidLayoutSubviewsではSafeAreaの取得ができている
        let topSafeAreaHeight = self.view.safeAreaInsets.top
        let bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
        
        let width:CGFloat = self.view.frame.width
        let height:CGFloat = self.view.frame.height

        if let rect = rect {
            let wvHeight:CGFloat = height-topSafeAreaHeight-bottomSafeAreaHeight-rect.height
            self.view.frame = CGRect(
                x: 0, y: 0,
                width: width, height: height-rect.height)
            self.view.bounds = CGRect(
                x: 0, y: 0,
                width: width, height: height-rect.height)
            self.view.layoutIfNeeded()


            webView.frame = CGRect(
                x: 0, y: 0,
                width: width, height: wvHeight)
            webView.bounds = CGRect(
                x: 0, y: 0,
                width: width, height: wvHeight)
            self.view.layoutIfNeeded()
            self.openKeyboard = true
        }
    }
    /** キーボードが閉じたときに呼び出されるメソッド */
    @objc func willHideKeyboard(_ notification:NSNotification){

        print(self.view.frame)
        print(self.view.bounds)
        print(self.webView.frame)
        print(self.webView.bounds)

        // viewDidLayoutSubviewsではSafeAreaの取得ができている
        let topSafeAreaHeight = self.view.safeAreaInsets.top
        let bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
        let width:CGFloat = self.view.frame.width
        let height:CGFloat = UIScreen.main.bounds.height
        let wvHeight = height-topSafeAreaHeight-bottomSafeAreaHeight
        webView.frame = CGRect(
                x: 0, y: topSafeAreaHeight,
                width: width, height: wvHeight)
        self.view.frame = UIScreen.main.bounds
        self.openKeyboard = false
        self.view.layoutIfNeeded()
        

    }
}

extension NSNotification {
    /** 通知から「表示されるキーボードの表示位置」を取得 */
    func rect()->CGRect?{
        let rowRect:NSValue? = self.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let rect:CGRect? = rowRect?.cgRectValue
        return rect
    }

}

