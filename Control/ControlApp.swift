//
//  ControlApp.swift
//  Control
//
//  Created by Jenny Swift on 8/6/2025.
//

import SwiftUI

@main
struct ControlApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var coreDataController = CoreDataController() // ✅ Shared instance

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(coreDataController) // ✅ Same instance shared across app
        }
    }
}



