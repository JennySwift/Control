//
//  LogListView.swift
//  Control
//
//  Created by Jenny Swift on 8/6/2025.
//

import SwiftUI
import CoreData

struct LogListView: View {
    @EnvironmentObject var coreDataController: CoreDataController
    
    var isEditingLogs: Bool
    @FocusState.Binding var focusedField: ContentView.LogFieldFocus?

    var onAppearLast: () -> Void

    var body: some View {
        List {
            ForEach(coreDataController.logs, id: \.objectID) { log in
                LogRowView(
                    log: log,
                    isEditingLogs: isEditingLogs,
                    focusedField: $focusedField.projectedValue
                )
                .onAppear {
                    // Detect when the last item appears to load more
                    if log == coreDataController.logs.last {
                        onAppearLast()
                    }
                }
            }
            .onDelete(perform: coreDataController.deleteLogs)
        }
        .listStyle(.plain) // or .insetGrouped, .grouped, etc. for style tweaks
    }
}

