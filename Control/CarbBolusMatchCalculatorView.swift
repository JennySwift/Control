import SwiftUI

struct BolusEntry: Identifiable {
    let id = UUID()
    var value: String
    var lastEdited: Date = Date()
}

struct CarbEntry: Identifiable {
    let id = UUID()
    var value: String
    var lastEdited: Date = Date()
}

struct CarbBolusMatchCalculatorView: View {
    @State private var bolusEntries: [BolusEntry] = [BolusEntry(value: "")]
    @State private var carbEntries: [CarbEntry] = [CarbEntry(value: "")]
    @State private var insulinToCarbRatio: String = "30"

    enum FocusField: Hashable {
        case bolus(UUID)
        case carb(UUID)
        case icr
    }

    @FocusState private var focusedField: FocusField?

    // Timer to trigger view updates every 60 seconds
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var totalBolusDecimal: Decimal {
        bolusEntries.compactMap { Decimal(string: $0.value) }.reduce(0, +)
    }

    private var totalCarbsDecimal: Decimal {
        carbEntries.compactMap { Decimal(string: $0.value) }.reduce(0, +)
    }

    private var icrDecimal: Decimal? {
        Decimal(string: insulinToCarbRatio)
    }

    private var carbCoverage: Decimal? {
        guard let icr = icrDecimal else { return nil }
        return totalBolusDecimal * icr
    }

    private var carbDifference: Decimal? {
        guard let coverage = carbCoverage else { return nil }
        return totalCarbsDecimal - coverage
    }

    private var resultMessage: String {
        guard let diff = carbDifference else {
            return "Please fill in all fields."
        }

        let diffDouble = (diff as NSDecimalNumber).doubleValue
        let roundedDiff = Int(diffDouble.rounded())

        if abs(roundedDiff) < 1 {
            return "✅ Carb match is close to perfect!"
        } else if roundedDiff > 0 {
            return "🟢 You could have used more insulin. \(roundedDiff)g more carbs than covered."
        } else {
            return "⚠️ You may have over-bolused. \(-roundedDiff)g extra insulin coverage."
        }
    }

    var body: some View {
        ZStack {
            Color.clear
                .onTapGesture {
                    focusedField = nil
                }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("💉 Bolus Entries").font(.headline)
                        ForEach($bolusEntries) { $entry in
                            VStack(alignment: .leading) {
                                TextField("Bolus", text: $entry.value)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .bolus(entry.id))
                                    .onChange(of: entry.value) { _ in
                                        if let index = bolusEntries.firstIndex(where: { $0.id == entry.id }) {
                                            bolusEntries[index].lastEdited = Date()
                                        }
                                    }
                                Text("Edited \(relativeTime(from: entry.lastEdited)) ago")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        HStack {
                            Button("➕ Add Bolus") {
                                let new = BolusEntry(value: "")
                                bolusEntries.append(new)
                                focusedField = .bolus(new.id)
                            }

                            if bolusEntries.count > 1 {
                                Spacer()
                                Button("➖ Remove Bolus", role: .destructive) {
                                    bolusEntries.removeLast()
                                }
                            }
                        }
                    }

                    Divider()

                    Group {
                        Text("🍇 Carb Entries").font(.headline)
                        ForEach($carbEntries) { $entry in
                            VStack(alignment: .leading) {
                                TextField("Carbs", text: $entry.value)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .carb(entry.id))
                                    .onChange(of: entry.value) { _ in
                                        if let index = carbEntries.firstIndex(where: { $0.id == entry.id }) {
                                            carbEntries[index].lastEdited = Date()
                                        }
                                    }
                                Text("Edited \(relativeTime(from: entry.lastEdited)) ago")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        HStack {
                            Button("➕ Add Carb") {
                                let new = CarbEntry(value: "")
                                carbEntries.append(new)
                                focusedField = .carb(new.id)
                            }

                            if carbEntries.count > 1 {
                                Spacer()
                                Button("➖ Remove Carb", role: .destructive) {
                                    carbEntries.removeLast()
                                }
                            }
                        }
                    }

                    Divider()

                    Group {
                        Text("⚙️ Insulin:Carb Ratio").font(.headline)
                        TextField("e.g. 30", text: $insulinToCarbRatio)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .icr)
                    }

                    Divider()

                    Group {
                        Text("📊 Results").font(.headline)
                        Text("Total Bolus: \(totalBolusDecimal.description) U")
                        Text("Total Carbs: \(totalCarbsDecimal.description) g")
                        if let coverage = carbCoverage {
                            Text("Covers ~\(coverage.description)g carbs")
                        }
                        Text(resultMessage)
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }

                    Divider()

                    Button("Clear All", role: .destructive) {
                        bolusEntries = [BolusEntry(value: "")]
                        carbEntries = [CarbEntry(value: "")]
                        insulinToCarbRatio = "30"
                        focusedField = nil
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Carb Matching")
        .onReceive(timer) { _ in } // This silently triggers view refresh
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }

    func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
