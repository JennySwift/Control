//
//  SyncStatusView.swift
//  Control
//
//  Created by Jenny Swift on 8/6/2025.
//

import SwiftUI

struct SyncStatusView: View {
    @ObservedObject private var syncManager = SyncManager.shared

    var body: some View {
        HStack {
            if let last = syncManager.lastSyncDate {
                Text("Last synced: \(last.formatted(date: .omitted, time: .standard))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                Text("No sync yet")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            Spacer()

            if syncManager.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.horizontal, 6)
            } else {
                Button("Sync Now") {
                    syncManager.triggerSync()
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear{
//            syncManager.printCloudKitEnvironment()
            syncManager.testCloudKit()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
