//
//  Constants.swift
//  traQ
//
//  Created by spa on 2021/01/21.
//

import Foundation

class traQConstants {
    static let defaultHost = "q.trap.jp"
    static let stagingHost = "traq-dev.tokyotech.org"

    static let defaultUrl = pathToUrl(path: "/", host: defaultHost)!
    static let stagingUrl = pathToUrl(path: "/", host: stagingHost)!
    
    static let userAgent = "traQ-iOS"
}
