//#if os(macOS)
//import AppKit
//#endif
//#if os(iOS)
//import UIKit
//#endif
//
//import CloudKit
//import UserNotifications
//
//// Create a base class for iOS and macOS compatibility
//#if os(iOS)
//class AppDelegate: UIResponder, UIApplicationDelegate {
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//            // Request notification permissions
//            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
//                if granted {
//                    print("Notification permissions granted")
//                } else {
//                    print("Notification permissions denied")
//                }
//            }
//
//            // Set the delegate to handle incoming notifications
//            UNUserNotificationCenter.current().delegate = self
//            return true
//        }
//
//        // Handle incoming notification (re-fetch the messages)
//        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//            // If a push notification arrives, call the handleNotification method
//            if response.notification.request.content.categoryIdentifier == "MessageNotification" {
//                // Trigger message fetch on the view model
//                if let rootView = UIApplication.shared.windows.first?.rootViewController as? UIHostingController<MessageView> {
//                    rootView.rootView.viewModel.fetchMessages()  // Refresh the message list
//                }
//            }
//            completionHandler()
//        }
//
//    func requestPushNotificationPermission() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
//            if granted {
//                print("Push notifications granted")
//                DispatchQueue.main.async {
//                    UIApplication.shared.registerForRemoteNotifications()
//                }
//            } else {
//                print("Push notifications denied")
//            }
//        }
//    }
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        // Send the deviceToken to your server to register for push notifications
//        print("Device Token: \(deviceToken)")
//    }
//
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("Failed to register for remote notifications: \(error)")
//    }
//
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        // Handle push notification
//        print("Received push notification: \(userInfo)")
//        completionHandler(.newData)
//    }
//    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
//        if let notification = CKQueryNotification(fromRemoteNotificationDictionary: userInfo) {
//            if let recordID = notification.recordID {
//                NotificationCenter.default.post(name: .newCloudKitData, object: recordID)
//            }
//        }
//    }
//    
//}
//#elseif os(macOS)
//class AppDelegate: NSObject, NSApplicationDelegate {
//    
//    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        // Send the deviceToken to your server to register for push notifications
//        print("Device Token: \(deviceToken)")
//    }
//
//    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("Failed to register for remote notifications: \(error)")
//    }
//
//    
//    
//    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
//        if let notification = CKQueryNotification(fromRemoteNotificationDictionary: userInfo) {
//            if let recordID = notification.recordID {
//                NotificationCenter.default.post(name: .newCloudKitData, object: recordID)
//            }
//        }
//    }
//    
//}
//#endif
//
//extension Notification.Name {
//    static let newCloudKitData = Notification.Name("newCloudKitData")
//}
