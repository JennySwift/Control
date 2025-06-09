//
//  LogsView.swift
//  Control
//
//  Created by Jenny Swift on 9/6/2025.
//

import SwiftUI

struct LogsView: View {
    @EnvironmentObject var coreDataController: CoreDataController
    @FocusState.Binding var focusedField: ContentView.LogFieldFocus?
    @State private var isEditingLogs: Bool = true
    
    var onAppearLast: () -> Void = {}
    
    var body: some View {
        NavigationStack {
            VStack {
                SyncStatusView()
                
                Toggle("Quick Edit Mode", isOn: $isEditingLogs)
                    .padding(.horizontal)
                
                LogListView(
                    isEditingLogs: isEditingLogs,
                    focusedField: $focusedField.projectedValue,
                    onAppearLast: onAppearLast
                )
            }
            .navigationTitle("BG Logs")
        }
    }
}

