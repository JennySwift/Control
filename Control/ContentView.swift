import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var coreDataController: CoreDataController
    @FocusState private var focusedField: LogFieldFocus?
    
    enum LogFieldFocus: Hashable {
        case start(NSManagedObjectID), bg(NSManagedObjectID), notes(NSManagedObjectID)
    }
    
    var body: some View {
        TabView {
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


