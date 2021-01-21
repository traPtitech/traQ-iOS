//
//  traQApp.swift
//  traQ
//
//  Created by spa on 2021/01/21.
//

import SwiftUI
import Firebase
import UserNotifications

@main
struct traQApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var store = ApplicationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { configHost() }
        }
    }
    
    init() {
        FirebaseApp.configure()
    }
    
    private func configHost() {
        // 2021-02-01T00:00:00+09:00
        let useStaging = Date() < Date.init(timeIntervalSince1970: 1612105200)
        store.host = useStaging ? traQConstants.stagingHost : traQConstants.defaultHost
        store.path = "/"
    }
}
