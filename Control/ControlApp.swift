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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
