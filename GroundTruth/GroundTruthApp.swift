//
//  GroundTruthApp.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck
import UserNotifications


final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate{
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            let providerFactory = AppCheckDebugProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
            FirebaseApp.configure()
        }
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Without this, a local notification that fires while the app is open and in
    // the foreground (e.g. during a live demo) is delivered silently — no banner.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}


@main
struct GroundTruthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @AppStorage(AccentColorStore.storageKey) private var accentColorHex = AccentColorStore.defaultHex

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Color(hex: accentColorHex) ?? .blue)
        }
    }
}
