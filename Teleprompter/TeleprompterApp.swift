//
//  TeleprompterApp.swift
//  Teleprompter
//
//  Created by abaig on 01/10/2024.
//

import SwiftUI
import UserNotifications

@main
struct TeleprompterApp: App {

    init() {
            // 1. Request permission
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
            
            // 2. Set delegate so notifications show in foreground
            UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        }
    
    var body: some Scene {
        WindowGroup {
            GlassesHomeView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: ContentItem.self)
    }
}


// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Show notifications even when app is open, expanded with banner and sound
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }
}
