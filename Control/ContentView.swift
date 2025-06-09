import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var store: Store
    @EnvironmentObject var coreDataController: CoreDataController
    
    @State private var fetchLimit = 20

    @State private var startDate: Date = Date()
    @State private var notes: String = "Sample notes"
    @State private var bolus: Decimal = 0.0
    @State private var netCarbs: Decimal = 0.0
    @State private var bgString: String = "5.6" // typical blood glucose value
    @State private var bolusString: String = "0"
    @State private var netCarbsString: String = "0"
    @State private var isEditingLogs: Bool = true

    enum LogFieldFocus: Hashable {
        case start(NSManagedObjectID), bg(NSManagedObjectID), notes(NSManagedObjectID)
    }



    @FocusState private var focusedField: LogFieldFocus?



    var body: some View {
        NavigationStack {
            VStack {
                SyncStatusView()

                Toggle("Quick Edit Mode", isOn: $isEditingLogs)
                    .padding(.horizontal)

                Form {
                    DatePicker("Start", selection: $startDate)
                    TextField("Notes", text: $notes)
                    TextField("BG (Decimal)", text: $bgString)
                        .modifier(PlatformKeyboardModifier())
                    TextField("Bolus)", text: $bolusString)
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
                
                LogListView(
                    isEditingLogs: isEditingLogs,
                    focusedField: $focusedField.projectedValue,
                    onAppearLast: loadMoreIfNeeded
                )


            }
            .navigationTitle("BG Logs")
        }
        .frame(minWidth: isMac ? 500 : nil, minHeight: isMac ? 600 : nil)
        .onAppear {
            coreDataController.getLogs()
//            TidepoolController().fetchTidepoolBGData(email: "", password: "")

        }
    }
    
    
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }


    private func loadMoreIfNeeded() {
        fetchLimit += 20
        coreDataController.getLogs()
    }

    private var isValidBG: Bool {
        Decimal(string: bgString) != nil
    }

    private func addLog() {
        guard let decimalBG = Decimal(string: bgString) else { return }
        guard let decimalBolus = Decimal(string: bolusString) else { return }
        guard let decimalNetCarbs = Decimal(string: netCarbsString) else { return }

        withAnimation {
            let newLog = Log(context: viewContext)
            newLog.start = startDate
            newLog.notes = notes
            newLog.bg = NSDecimalNumber(decimal: decimalBG)
            newLog.bolus = NSDecimalNumber(decimal: decimalBolus)
            newLog.netCarbs = NSDecimalNumber(decimal: decimalNetCarbs)

            do {
                try viewContext.save()
                
                //This is for quick testing of my app so it's a new start for each log
                startDate = startDate.addingTimeInterval(60) // +1 minute

//                startDate = Date() // resets to "now" after every tap
                notes = "Sample notes"
                bgString = "5.6"
                bolusString = "0"
                netCarbsString = "0"

                coreDataController.getLogs()
            } catch {
                print("Save error: \(error)")
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    private var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
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

