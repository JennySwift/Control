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
//    @State private var notes: String = currentTimeString() // Initialize with current time
    @State private var notes: String = ""
    @State private var bgString: String = ""
    @State private var bolusString: String = ""
    @State private var netCarbsString: String = ""
    
    // State variable to control sheet presentation
    @State private var isShowingDatePicker = false
    
    private var isValidBG: Bool {
        Decimal(string: bgString) != nil
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                SyncStatusView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Time Picker Row
                        HStack {
                            Button(action: {
                                isShowingDatePicker = true
                            }) {
                                Text(startDate, style: .time)
                                    .font(.title2)
                                    .frame(minWidth: 100, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemGray))
                                    .cornerRadius(8)
                            }

                            Spacer()

                            Button("Now") {
                                startDate = Date()
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }

                        // Notes
                        TextField("Notes", text: $notes)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        // BG
                        TextField("BG (Decimal)", text: $bgString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .modifier(PlatformKeyboardModifier())

                        // Bolus
                        TextField("Bolus", text: $bolusString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .modifier(PlatformKeyboardModifier())

                        // Net Carbs
                        TextField("Net Carbs", text: $netCarbsString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .modifier(PlatformKeyboardModifier())

                        // Add Log Button
                        HStack {
                            Spacer()
                            Button("Add Log", action: addLog)
                                .disabled(!isValidBG)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(isValidBG ? Color.accentColor : Color.gray.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(20)
                }
                .sheet(isPresented: $isShowingDatePicker) {
                    VStack(spacing: 0) {
                        DatePicker(
                            "Select Date & Time",
                            selection: $startDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        #if(iOS)
                        .datePickerStyle(WheelDatePickerStyle())
                        #endif
                        .labelsHidden()
                        .frame(maxHeight: .infinity)

                        Divider()

                        Button("Done") {
                            isShowingDatePicker = false
                        }
                        .padding()
                    }
                    .padding(0)
                    .edgesIgnoringSafeArea(.bottom)
                    .presentationDetents([.medium, .large])
                }

                
//                Form {
//                    VStack(alignment: .leading, spacing: 8) {
//                        HStack {
//                            Button(action: {
//                                isShowingDatePicker = true
//                            }) {
//                                Text(startDate, style: .time)
//                                    .font(.title2)
//                                    .frame(minWidth: 100)
//                            }
//                            Spacer()
//                            Button("Now") {
//                                startDate = Date()
//                            }
//                            .buttonStyle(BorderlessButtonStyle())
//                        }
////                        .padding(.horizontal)
//                        
//                        
//                        
//                        .sheet(isPresented: $isShowingDatePicker) {
//                            VStack(spacing: 0) {
//                                DatePicker(
//                                    "Select Date & Time",
//                                    selection: $startDate,
//                                    displayedComponents: [.date, .hourAndMinute]
//                                )
//                                .datePickerStyle(WheelDatePickerStyle())
//                                .labelsHidden()
//                                .padding()
//                                .frame(maxHeight: .infinity)
//                                Divider()
//                                Button("Done") {
//                                    isShowingDatePicker = false
//                                }
//                                .padding()
//                            }
//                            .padding(0)
//                            .edgesIgnoringSafeArea(.bottom)
//                            .presentationDetents([.medium, .large]) // Requires iOS 16 / macOS 13+
//                        }
//                    }
//                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
//                    
//                    
//                    
//                    TextField("Notes", text: $notes)
//                    TextField("BG (Decimal)", text: $bgString)
//                        .modifier(PlatformKeyboardModifier())
//                    TextField("Bolus", text: $bolusString)
//                        .modifier(PlatformKeyboardModifier())
//                    TextField("Net Carbs", text: $netCarbsString)
//                        .modifier(PlatformKeyboardModifier())
//                    
//                    HStack {
//                        Spacer()
//                        Button("Add Log", action: addLog)
//                            .disabled(!isValidBG)
//                    }
//                }
//                .padding(0)
            }
            .navigationTitle("New Log")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    
    private func addLog() {
        guard let decimalBG = Decimal(string: bgString),
              let decimalBolus = Decimal(string: bolusString),
              let decimalNetCarbs = Decimal(string: netCarbsString) else { return }
        
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
            bgString = ""
            bolusString = ""
            netCarbsString = ""
            
            coreDataController.getLogs()
        } catch {
            print("Save error: \(error)")
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
