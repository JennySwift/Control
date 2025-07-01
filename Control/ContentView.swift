import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var coreDataController: CoreDataController
    @FocusState private var focusedField: LogFieldFocus?
    @StateObject private var dexcomClient = DexcomClient()
    
    enum LogFieldFocus: Hashable {
        case start(NSManagedObjectID), bg(NSManagedObjectID), notes(NSManagedObjectID)
    }
    
    var body: some View {
        TabView {
            
            GlucoseChartView()
                .tabItem {
                    Label("BG", systemImage: "chart.xyaxis.line")
                }
            
            DexcomView()
                .environmentObject(dexcomClient)
                .tabItem {
                    Label("Dexcom", systemImage: "drop.fill")
                }

            CorrectionBolusCalculatorView()
                .environmentObject(dexcomClient)
                .tabItem {
                    Label("Correction", systemImage: "syringe")
                }
            
            CarbBolusMatchCalculatorView()
                .tabItem {
                    Label("Carb Match", systemImage: "scalemass")
                }
            
            NewLogView()
                .tabItem {
                    Label("New Log", systemImage: "plus.circle")
                }
            
            LogsView(focusedField: $focusedField) {
                // onAppearLast closure if needed
                coreDataController.getLogs()
            }
            .tabItem {
                Label("Logs", systemImage: "list.bullet")
            }
        }
        .onAppear {
            coreDataController.getLogs()
        }
    }
}



