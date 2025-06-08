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
        context.perform {
            do {
                try context.save()
            } catch {
                print("Error saving before sync: \(error)")
            }
        }

        // Simulate delay and update timestamp
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSyncing = false
            self.lastSyncDate = Date()
        }
    }

    
    private func startListening() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.lastSyncDate = Date()
            }
            .store(in: &cancellables)
    }
}


