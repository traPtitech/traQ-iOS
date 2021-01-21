//
//  UrlUtils.swift
//  traQ
//
//  Created by spa on 2021/01/21.
//

import Foundation

func pathToUrl(path: String, host: String) -> URL? {
    guard path.starts(with: "/") else {
        return nil
    }
    return URL(string: "https://\(host)\(path)")
}
