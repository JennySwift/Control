import SwiftUI
import CoreData

struct LogRowView: View {
    @Environment(\.managedObjectContext) private var viewContext

    let log: Log
    let isEditingLogs: Bool
    @FocusState.Binding var focusedField: ContentView.LogFieldFocus?

    @State private var tempStart: Date = Date()
    @State private var tempBG: String = ""
    @State private var tempBolus: String = ""
    @State private var tempCarbs: String = ""
    @State private var tempNotes: String = ""

    @State private var isStartDirty = false
    @State private var isBGDirty = false
    @State private var isBolusDirty = false
    @State private var isCarbsDirty = false
    @State private var isNotesDirty = false

    var body: some View {
        let id = log.objectID

        VStack(alignment: .leading, spacing: 4) {
            if isEditingLogs {
                // Start
                DatePicker("Start", selection: $tempStart, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: tempStart) { newValue in
                        if newValue != (log.start ?? Date()) {
                            log.start = newValue
                            save()
                            highlightDirty($isStartDirty)
                        }
                    }
                    .background(isStartDirty ? Color.yellow.opacity(0.3) : Color.clear)
                    .cornerRadius(6)

                // BG
                TextField("BG", text: $tempBG)
                    .focused($focusedField, equals: .bg(id))
                    .onChange(of: tempBG) { newValue in
                        if let value = Decimal(string: newValue),
                           value != (log.bg?.decimalValue ?? 0) {
                            log.bg = NSDecimalNumber(decimal: value)
                            save()
                            highlightDirty($isBGDirty)
                        }
                    }
                    .background(isBGDirty ? Color.yellow.opacity(0.3) : Color.clear)
                    .cornerRadius(6)

                // Bolus
                TextField("Bolus", text: $tempBolus)
                    .onChange(of: tempBolus) { newValue in
                        if let value = Decimal(string: newValue),
                           value != (log.bolus?.decimalValue ?? 0) {
                            log.bolus = NSDecimalNumber(decimal: value)
                            save()
                            highlightDirty($isBolusDirty)
                        }
                    }
                    .background(isBolusDirty ? Color.yellow.opacity(0.3) : Color.clear)
                    .cornerRadius(6)

                // Carbs
                TextField("Net Carbs", text: $tempCarbs)
                    .onChange(of: tempCarbs) { newValue in
                        if let value = Decimal(string: newValue),
                           value != (log.netCarbs?.decimalValue ?? 0) {
                            log.netCarbs = NSDecimalNumber(decimal: value)
                            save()
                            highlightDirty($isCarbsDirty)
                        }
                    }
                    .background(isCarbsDirty ? Color.yellow.opacity(0.3) : Color.clear)
                    .cornerRadius(6)

                // Notes
                TextField("Notes", text: $tempNotes)
                    .focused($focusedField, equals: .notes(id))
                    .onChange(of: tempNotes) { newValue in
                        if newValue != (log.notes ?? "") {
                            log.notes = newValue
                            save()
                            highlightDirty($isNotesDirty)
                        }
                    }
                    .background(isNotesDirty ? Color.yellow.opacity(0.3) : Color.clear)
                    .cornerRadius(6)

            } else {
                Text("Start: \(log.start ?? Date(), formatter: dateFormatter)")
                Text("BG: \(log.bg?.stringValue ?? "-")")
                Text("Bolus: \(log.bolus?.stringValue ?? "-")")
                Text("Net Carbs: \(log.netCarbs?.stringValue ?? "-")")
                Text("Notes: \(log.notes ?? "")")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 6)
        .onAppear {
            tempStart = log.start ?? Date()
            tempBG = log.bg?.stringValue ?? ""
            tempBolus = log.bolus?.stringValue ?? ""
            tempCarbs = log.netCarbs?.stringValue ?? ""
            tempNotes = log.notes ?? ""
        }
    }

    private func highlightDirty(_ flag: Binding<Bool>) {
        flag.wrappedValue = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                flag.wrappedValue = false
            }
        }
    }

    private func save() {
        do {
            try viewContext.save()
        } catch {
            print("Save failed: \(error)")
        }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }
}

