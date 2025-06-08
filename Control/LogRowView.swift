
import SwiftUI
import CoreData

struct LogRowView: View {
    @Environment(\.managedObjectContext) private var viewContext

    let log: Log
    let isEditingLogs: Bool

    @State private var tempBG: String = ""
    @State private var tempNotes: String = ""
    @State private var tempStart: Date = Date()

    @State private var isStartDirty = false
    @State private var isBGDirty = false
    @State private var isNotesDirty = false

    @FocusState.Binding var focusedField: ContentView.LogFieldFocus?

    var body: some View {
        let id = log.objectID

        VStack(alignment: .leading, spacing: 4) {
            if isEditingLogs {
                // START
                DatePicker("Start", selection: $tempStart, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: tempStart) {
                        if tempStart != (log.start ?? Date()) {
                            isStartDirty = true
                            log.start = tempStart
                            saveContext()
                            delayClearDirtyFlag(flag: $isStartDirty)
                        }
                    }
                    .background(isStartDirty ? Color.yellow.opacity(0.3) : Color.clear)
                    .cornerRadius(6)

                // BG
                TextField("BG", text: $tempBG)
                    .focused($focusedField, equals: .bg(id))
                    .onChange(of: tempBG) {
                        if let decimal = Decimal(string: tempBG),
                           decimal != (log.bg?.decimalValue ?? Decimal.zero) {
                            isBGDirty = true
                            log.bg = NSDecimalNumber(decimal: decimal)
                            saveContext()
                            tempBG = log.bg?.stringValue ?? ""
                            delayClearDirtyFlag(flag: $isBGDirty)
                        }
                    }
                    .modifier(PlatformKeyboardModifier())
                    .background(isBGDirty ? Color.yellow.opacity(0.3) : Color.clear)
                    .cornerRadius(6)

                // NOTES
                TextField("Notes", text: $tempNotes)
                    .focused($focusedField, equals: .notes(id))
                    .onChange(of: tempNotes) {
                        if tempNotes != (log.notes ?? "") {
                            isNotesDirty = true
                            log.notes = tempNotes
                            saveContext()
                            tempNotes = log.notes ?? ""
                            delayClearDirtyFlag(flag: $isNotesDirty)
                        }
                    }
                    .background(isNotesDirty ? Color.yellow.opacity(0.3) : Color.clear)
                    .cornerRadius(6)

            } else {
                Text("Start: \(log.start ?? Date(), formatter: dateFormatter)")
                Text("BG: \(log.bg?.stringValue ?? "-")")
                Text("Notes: \(log.notes ?? "")")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 6)
        .onAppear {
            tempBG = log.bg?.stringValue ?? ""
            tempNotes = log.notes ?? ""
            tempStart = log.start ?? Date()
        }
    }

    private func delayClearDirtyFlag(flag: Binding<Bool>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            flag.wrappedValue = false
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Save error: \(error)")
        }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }
}
