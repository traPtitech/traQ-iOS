//
//  ViewController.swift
//  traQ-iOS
//
//  Created by とーふとふ on 2018/06/20.
//  Copyright © 2018年 traP. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    
    override func viewDidLoad(){
        super.viewDidLoad()

        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        
        let webUrl = URL(string: "https://traq-dev.tokyotech.org")!
        let myRequest = URLRequest(url: webUrl)
        webView.load(myRequest)
        
        // インスタンスをビューに追加する
        self.view.addSubview(webView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

