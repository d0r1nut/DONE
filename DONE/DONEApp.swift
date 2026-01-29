//
//  DONEApp.swift
//  DONE
//
//  Created by Dmytro Hannotskyi on 2026-01-29.
//

import SwiftUI
import CoreData

@main
struct DONEApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
