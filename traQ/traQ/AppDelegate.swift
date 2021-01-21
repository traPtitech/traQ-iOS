//
//  AppDelegate.swift
//  traQ
//
//  Created by spa on 2021/01/22.
//

import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register remote notification
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            guard error != nil, granted else {
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let path = notification.request.content.userInfo["path"] as? String else {
            return
        }
        NotificationCenter.default.post(name: .traQRemoteNotificationReceived, object: nil, userInfo: ["path": path])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let path = response.notification.request.content.userInfo["path"] as? String else {
            return
        }
        NotificationCenter.default.post(name: .traQRemoteNotificationReceived, object: nil, userInfo: ["path": path])
    }
}

extension Notification.Name {
    static let traQRemoteNotificationReceived = Notification.Name("tech.trapti.remoteNotificationReceived")
}
