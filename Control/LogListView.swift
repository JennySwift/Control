//
//  LogListView.swift
//  Control
//
//  Created by Jenny Swift on 8/6/2025.
//

import SwiftUI
import CoreData


struct LogListView: View {
    var logs: [Log]
    var isEditingLogs: Bool
//    @Binding var focusedField: ContentView.LogFieldFocus?
    @FocusState.Binding var focusedField: ContentView.LogFieldFocus?

    var onAppearLast: () -> Void

    var body: some View {
        
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(logs, id: \.objectID) { log in

                    
                    LogRowView(
                        log: log,
                        isEditingLogs: isEditingLogs,
                        focusedField: $focusedField.projectedValue
//                        logs: logs,
//                        saveContext: saveContext
                    )
                    
                    Divider()
                }

            }
            .padding()
        }
        
        
        
    }
}

