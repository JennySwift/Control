//
//  CoreDataController.swift
//  Control
//
//  Created by Jenny Swift on 9/6/2025.
//

import Foundation
import CoreData

class CoreDataController: ObservableObject {
    let context = PersistenceController.shared.container.viewContext
    
    @Published var logs: [Log] = []
    
    init() {
        getLogs()

        NotificationCenter.default.addObserver(
            forName: .remoteChangeHandled,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔄 CoreDataController detected remote sync. Refetching logs.")
            self?.getLogs()
        }
    }

    public func getLogs() {
        let request: NSFetchRequest<Log> = Log.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Log.start, ascending: false)]
        request.fetchLimit = 20

        do {
            context.refreshAllObjects() // 🧹 Clears Core Data's cache
            let fetchedLogs = try context.fetch(request)
            print("✅ logs fetched from Core Data: \(fetchedLogs.count) logs")

            DispatchQueue.main.async {
                self.logs = fetchedLogs
            }
        } catch {
            print("❌ Failed to fetch logs: \(error)")
        }
    }
    
    //This will only delete one log if it was swiped on, but also handles multi-selection capability
    public func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            let log = logs[index]
            context.delete(log)
        }
        saveContext()
        getLogs() // Refresh logs after deletion
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

