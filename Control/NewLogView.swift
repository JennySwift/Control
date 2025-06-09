//
//  NewLogView.swift
//  Control
//
//  Created by Jenny Swift on 9/6/2025.
//

import SwiftUI
import CoreData

struct NewLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var coreDataController: CoreDataController
    
    @State private var startDate: Date = Date()
    @State private var notes: String = currentTimeString() // Initialize with current time
    @State private var bgString: String = "5.6"
    @State private var bolusString: String = "0"
    @State private var netCarbsString: String = "0"
    
    private var isValidBG: Bool {
        Decimal(string: bgString) != nil
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                SyncStatusView()
                
                Form {
                    HStack {
                        DatePicker("Start", selection: $startDate)
                        Button("Now") {
                            startDate = Date()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    TextField("Notes", text: $notes)
                    TextField("BG (Decimal)", text: $bgString)
                        .modifier(PlatformKeyboardModifier())
                    TextField("Bolus", text: $bolusString)
                        .modifier(PlatformKeyboardModifier())
                    TextField("Net Carbs", text: $netCarbsString)
                        .modifier(PlatformKeyboardModifier())
                    
                    HStack {
                        Spacer()
                        Button("Add Log", action: addLog)
                            .disabled(!isValidBG)
                    }
                }
                .padding()
            }
            .navigationTitle("New Log")
        }
    }
    
    private func addLog() {
        guard let decimalBG = Decimal(string: bgString),
              let decimalBolus = Decimal(string: bolusString),
              let decimalNetCarbs = Decimal(string: netCarbsString) else { return }
        
        withAnimation {
            let newLog = Log(context: viewContext)
            newLog.start = startDate
            newLog.notes = notes
            newLog.bg = NSDecimalNumber(decimal: decimalBG)
            newLog.bolus = NSDecimalNumber(decimal: decimalBolus)
            newLog.netCarbs = NSDecimalNumber(decimal: decimalNetCarbs)
            
            do {
                try viewContext.save()
                
                // Optional: Reset form after add
                startDate = Date()
                notes = currentTimeString()
                bgString = "5.6"
                bolusString = "0"
                netCarbsString = "0"
                
                coreDataController.getLogs()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}

struct PlatformKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.keyboardType(.decimalPad)
        #else
        content
        #endif
    }
}
