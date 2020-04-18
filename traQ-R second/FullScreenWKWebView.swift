//
//  FullScreenWKWebView.swift
//  traQ-R second
//
//  Created by spaspa on 2020/04/17.
//

import Foundation
import WebKit

class FullScreenWKWebView: WKWebView {
    override var safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
