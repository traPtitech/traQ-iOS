//
//  MyWebViewViewController.swift
//  traQ-iOS
//
//  Created by とーふとふ on 2018/06/21.
//  Copyright © 2018年 traP. All rights reserved.
//

import UIKit
import WebKit

class MyWebViewViewController: UIViewController {
    var myWebView: WKWebView!
    
    // adjust SafeArea top space
    // portrait のみを想定
    var topPadding:CGFloat = 0
    
    override func viewDidAppear(_ animated: Bool){
        print("viewDidAppear")
        
        let screenWidth:CGFloat = view.frame.size.width
        let screenHeight:CGFloat = view.frame.size.height
        
        // iPhone X , X以外は0となる
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            topPadding = window!.safeAreaInsets.top
        }
        
        // Webページの大きさを画面に合わせる
        let rect = CGRect(x: 0,
                          y: topPadding,
                          width: screenWidth,
                          height: screenHeight - topPadding)
        
        let webConfiguration = WKWebViewConfiguration()
        myWebView = WKWebView(frame: rect, configuration: webConfiguration)
        
        let webUrl = URL(string: "https://traq-dev.tokyotech.org")!
        let myRequest = URLRequest(url: webUrl)
        myWebView.load(myRequest)
        
        // インスタンスをビューに追加する
        self.view.addSubview(myWebView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
