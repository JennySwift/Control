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
        // ✅ Observe remote changes
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📡 Remote change received!")
            self?.getLogs()
        }
    }

    public func getLogs() {
        var sortDescriptors = [
            NSSortDescriptor(key: "start", ascending: false)
        ]
        
        let request: NSFetchRequest<Log> = Log.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Log.start, ascending: false)]
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = 20

        do {
            let fetchedLogs = try context.fetch(request)
            print("logs fetched: \(logs.count)")
            DispatchQueue.main.async {
                self.logs = fetchedLogs
            }
        } catch {
            print("Failed to fetch logs: \(error)")
        }
                
    }
}

