//
//  DONEApp.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-01-29.
//

import SwiftUI
import CoreData
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        
        return true
    }
    
    // Ask the user for permission (Banners, Sounds, Badges)
    func requestNotificationPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                print("Notification Permission Granted")
            } else if let error = error {
                print("Notification Error: \(error.localizedDescription)")
            }
        }
    }
    
    // OPTIONAL: This function lets notifications show up even when the app is OPEN
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

@main
struct DONEApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var authVM = AuthenticationViewModel()
    let persistenceController = PersistenceController.shared
    @StateObject var dateHolder = DateHolder(PersistenceController.shared.container.viewContext)
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.userSession != nil {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(dateHolder)
                } else {
                    NavigationStack {
                        LoginView()
                    }
                }
            }
            .environmentObject(authVM)
        }
    }
}
