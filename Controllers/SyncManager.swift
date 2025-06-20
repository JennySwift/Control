//
//  SyncManager.swift
//  Control
//
//  Created by Jenny Swift on 8/6/2025.
//

import Foundation
import CoreData
import CloudKit
import Combine

final class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published var lastSyncDate: Date?
    @Published var isSyncing: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private var container: NSPersistentCloudKitContainer {
        PersistenceController.shared.container
    }

    private init() {
        startListening()
    }
    
    func triggerSync() {
        guard !isSyncing else { return }
        isSyncing = true

        let context = container.viewContext

        // Save local changes first
        context.perform {
            do {
                try context.save()
            } catch {
                print("Error saving before sync: \(error)")
            }

            // After save, fetch changes from CloudKit
            self.fetchCloudKitChanges()
        }
    }

    private func fetchCloudKitChanges() {
//        let container = PersistenceController.shared.container
//        let coordinator = container.persistentStoreCoordinator
//
//        coordinator.perform {
//            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: nil)
//
//            do {
//                let result = try coordinator.execute(request, with: container.viewContext)
//                if let historyResult = result as? NSPersistentHistoryResult,
//                   let transactions = historyResult.result as? [NSPersistentHistoryTransaction],
//                   !transactions.isEmpty {
//                    
//                    print("Fetched \(transactions.count) transactions")
//
//                    DispatchQueue.main.async {
//                        self.getLogs()
//                        self.lastSyncDate = Date()
//                    }
//                }
//            } catch {
//                print("Failed to fetch history: \(error)")
//            }
//        }
    }




//    func triggerSync() {
//        guard !isSyncing else { return }
//
//        isSyncing = true
//
//        let context = container.viewContext
//        context.perform {
//            do {
//                try context.save()
//            } catch {
//                print("Error saving before sync: \(error)")
//            }
//        }
//
//        // Simulate delay and update timestamp
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.isSyncing = false
//            self.lastSyncDate = Date()
//        }
//    }
    
    public func testCloudKit () {
        let record = CKRecord(recordType: "Log")
        record["notes"] = "Testing from iPhone"
        // Add other fields...

        CKContainer.default().privateCloudDatabase.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ CloudKit save failed: \(error.localizedDescription)")
                } else {
                    print("✅ Log saved to CloudKit: \(savedRecord!)")
                }
            }
        }

    }
    

    public func printCloudKitEnvironment() {
        let container = CKContainer.default()
        container.accountStatus { status, error in
            if let error = error {
                print("iCloud error: \(error)")
            } else {
                switch status {
                case .available: print("✅ iCloud available")
                case .noAccount: print("❌ No iCloud account")
                case .restricted: print("❌ iCloud restricted")
                case .couldNotDetermine: print("❌ Could not determine iCloud status")
                @unknown default: break
                }
            }
            
            print("Container ID: \(container.containerIdentifier ?? "nil")")
        }
    }


    
    private func startListening() {
        let viewContext = container.viewContext
        
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.lastSyncDate = Date()
            }
            .store(in: &cancellables)
        
        
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: viewContext, queue: .main) { notification in
            if let inserts = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>, !inserts.isEmpty {
                print("Inserted objects: \(inserts)")
                // Update UI accordingly
            }
            
            if let updates = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updates.isEmpty {
                print("Updated objects: \(updates)")
                // Update UI accordingly
            }
            
            if let deletes = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletes.isEmpty {
                print("Deleted objects: \(deletes)")
                // Update UI accordingly
            }
        }

//        NotificationCenter.default.addObserver(
//            forName: .NSPersistentStoreRemoteChange,
//            object: container.persistentStoreCoordinator,
//            queue: .main
//        ) { notification in
//            print("Remote change received!")
//            // Reload your UI or fetch logs again
//        }

    }
}


