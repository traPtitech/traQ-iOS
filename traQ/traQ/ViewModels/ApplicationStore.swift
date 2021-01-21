//
//  ApplicationStore.swift
//  traQ
//
//  Created by spa on 2021/01/22.
//

import Foundation
import Combine

class ApplicationStore: ObservableObject {
    @Published var url: URL?
    
    var path: String = traQConstants.defaultHost {
        didSet { url = pathToUrl(path: path, host: host) }
    }

    var host: String = "/" {
        didSet { url = pathToUrl(path: path, host: host) }
    }
    
    init() {
        let _ = NotificationCenter.default.publisher(for: .traQRemoteNotificationReceived, object: nil).sink { notification in
            guard let path = notification.userInfo?["path"] as? String else {
                return
            }
            self.path = path
        }
    }
}
