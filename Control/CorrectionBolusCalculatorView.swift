//
//  CorrectionBolusCalculatorView.swift
//  Control
//
//  Created by Jenny Swift on 28/6/2025.
//

import SwiftUI

struct CorrectionBolusCalculatorView: View {
    @EnvironmentObject var dexcomClient: DexcomClient
    @State private var currentBg: String = ""
    @State private var targetBg: String = "4.0"
    @State private var correctionFactor: String = "3.5"
    @State private var iob: String = "0"
    

    @FocusState private var focusedField: Field?

    enum Field {
        case currentBg, targetBg, correctionFactor, iob
    }

    private var currentBgDecimal: Decimal? {
        Decimal(string: currentBg)
    }

    private var targetBgDecimal: Decimal? {
        Decimal(string: targetBg)
    }

    private var correctionFactorDecimal: Decimal? {
        Decimal(string: correctionFactor)
    }
    
    private var iobDecimal: Decimal {
        Decimal(string: iob) ?? 0
    }

    private var correctionDoseDecimal: Decimal? {
        guard
            let current = currentBgDecimal,
            let target = targetBgDecimal,
            let cf = correctionFactorDecimal,
            cf != 0
        else {
            return nil
        }

        let rawDose = (current - target) / cf - iobDecimal
        return max(rawDose, 0)
    }

    private var formattedCorrectionDose: String {
        if let dose = correctionDoseDecimal {
            let number = dose as NSDecimalNumber
            return numberFormatter.string(from: number) ?? "—"
        } else {
            return "—"
        }
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.onTapGesture { focusedField = nil }
                Form {
                    Section(header: Text("Correction Calculator")) {
                        calculatorTextField(label: "Current BG", value: $currentBg, field: .currentBg)
                        calculatorTextField(label: "Target BG", value: $targetBg, field: .targetBg)
                        calculatorTextField(label: "Correction Factor", value: $correctionFactor, field: .correctionFactor)
                        calculatorTextField(label: "Insulin on Board (IOB)", value: $iob, field: .iob)
                    }
                    
                    Section(header: Text("Suggested Correction")) {
                        Text("\(formattedCorrectionDose) units")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .navigationTitle("Correction Dose")
                .floatingDoneButton(focusedField: $focusedField)
            }
        }
        .onChange(of: dexcomClient.bgValue) { newValue in
            if let value = Double(newValue.components(separatedBy: " ").first ?? "") {
                currentBg = String(format: "%.1f", value)
            }
        }
    }

    @ViewBuilder
    private func calculatorTextField(label: String, value: Binding<String>, field: Field) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: field)
                .onChange(of: focusedField) { newFocus in
                    if newFocus == field {
                        value.wrappedValue = ""
                    }
                }
        }
    }
}

