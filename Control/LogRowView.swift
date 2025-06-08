import SwiftUI
import CoreData

struct LogRowView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var log: Log

    let isEditingLogs: Bool

    @State private var tempBG: String = ""
    @State private var tempNotes: String = ""
    @State private var tempStart: Date = Date()

    @FocusState.Binding var focusedField: ContentView.LogFieldFocus?

    var body: some View {
        let id = log.objectID

        VStack(alignment: .leading, spacing: 4) {
            if isEditingLogs {
                DatePicker("Start", selection: $tempStart, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: tempStart) { newValue in
                        if newValue != (log.start ?? Date()) {
                            log.start = newValue
                            saveAndResync()
                            tempStart = log.start ?? Date()
                        }
                    }
                    .background(isStartDirty ? Color.yellow.opacity(0.3) : Color.clear)
                    .cornerRadius(6)

                TextField("BG", text: $tempBG)
                    .focused($focusedField, equals: .bg(id))
                    .onSubmit {
                        if let decimal = Decimal(string: tempBG),
                           decimal != (log.bg?.decimalValue ?? Decimal.zero) {
                            log.bg = NSDecimalNumber(decimal: decimal)
                            saveAndResync()
                            tempBG = log.bg?.stringValue ?? ""
                        }
                        focusedField = .notes(id)
                    }
                    .modifier(PlatformKeyboardModifier())
                    .background(isBGDirty ? Color.yellow.opacity(0.3) : Color.clear)
                    .cornerRadius(6)

                TextField("Notes", text: $tempNotes)
                    .focused($focusedField, equals: .notes(id))
                    .onSubmit {
                        if tempNotes != (log.notes ?? "") {
                            log.notes = tempNotes
                            saveAndResync()
                            tempNotes = log.notes ?? ""
                        }

                        if let nextLog = findNextLog() {
                            focusedField = .bg(nextLog.objectID)
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
            syncTempValues()
        }
    }

    private func saveAndResync() {
        do {
            try viewContext.save()
            // Sync on next render pass
            DispatchQueue.main.async {
                syncTempValues()
            }
        } catch {
            print("Save error: \(error)")
        }
    }

    private func syncTempValues() {
        tempStart = log.start ?? Date()
        tempBG = log.bg?.stringValue ?? ""
        tempNotes = log.notes ?? ""
    }

    private var isStartDirty: Bool {
        (log.start ?? Date()) != tempStart
    }

    private var isBGDirty: Bool {
        guard let original = log.bg?.decimalValue,
              let current = Decimal(string: tempBG) else { return false }
        return original != current
    }

    private var isNotesDirty: Bool {
        (log.notes ?? "") != tempNotes
    }

    private func findNextLog() -> Log? {
        guard let logs = try? viewContext.fetch(Log.fetchRequest()) as? [Log],
              let currentIndex = logs.firstIndex(of: log),
              currentIndex + 1 < logs.count else { return nil }
        return logs[currentIndex + 1]
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }
}

