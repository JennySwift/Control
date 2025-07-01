
// HealthKitManager.swift
// Fetch Dexcom CGM data from Apple Health (last 3 days)

import HealthKit
import Foundation
import SwiftUI
import Charts

struct GlucoseReading: Identifiable {
    let id = UUID()
    let value: Double      // mmol/L
    let timestamp: Date
}

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!

        healthStore.requestAuthorization(toShare: [], read: [glucoseType]) { success, _ in
            completion(success)
        }
    }

    func checkAuthorizationStatus() -> Bool {
        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            return false
        }

        let status = healthStore.authorizationStatus(for: glucoseType)
        return status == .sharingAuthorized
    }

    func fetchGlucoseData(completion: @escaping ([GlucoseReading]) -> Void) {
        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            completion([])
            return
        }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [])

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: glucoseType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in

            guard let samples = results as? [HKQuantitySample], error == nil else {
                completion([])
                return
            }

            let readings = samples.map { sample in
                let unit = HKUnit.moleUnit(with: .milli, molarMass: 180.15588).unitDivided(by: .liter())
                let mmolPerL = sample.quantity.doubleValue(for: unit)
                return GlucoseReading(value: mmolPerL, timestamp: sample.startDate)
            }

            DispatchQueue.main.async {
                completion(readings)
            }
        }

        healthStore.execute(query)
    }
}

// MARK: - SwiftUI Preview Graph View

struct GlucoseChartView: View {
    @StateObject var manager = HealthKitManager()
    @State private var readings: [GlucoseReading] = []
    @State private var selectedReading: GlucoseReading? = nil
    @State private var zoomHours: Int = 3
    @State private var viewOffset: Int = 0
    @State private var targetLow: Double = 4.0
    @State private var targetHigh: Double = 10.0

    private var zoomedReadings: [GlucoseReading] {
        let endDate = Calendar.current.date(byAdding: .hour, value: -viewOffset, to: Date()) ?? Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -zoomHours, to: endDate) ?? endDate
        return readings.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    var body: some View {
        VStack(spacing: 8) {
            if let selected = selectedReading {
                Text("BG: \(String(format: "%.1f", selected.value)) at \(selected.timestamp.formatted(date: .omitted, time: .shortened))")
                    .font(.headline)
            }

            if readings.isEmpty {
                ProgressView("Loading glucose data...")
                    .onAppear {
                        manager.requestAuthorization { success in
                            if success {
                                manager.fetchGlucoseData { result in
                                    self.readings = result
                                }
                            }
                        }
                    }
            } else {
                Chart(zoomedReadings) { reading in
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("BG", reading.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(reading.value < targetLow || reading.value > targetHigh ? .red : .green)

                    PointMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("BG", reading.value)
                    )
                    .foregroundStyle(.gray)

                    if let selected = selectedReading, selected.id == reading.id {
                        RuleMark(x: .value("Time", selected.timestamp))
                            .foregroundStyle(Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(Color.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 10)
                                    .onChanged { value in
                                        let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                        if let date: Date = proxy.value(atX: x) {
                                            if let closest = zoomedReadings.min(by: { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) }) {
                                                selectedReading = closest
                                            }
                                        }
                                    }
                            )
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 300)
                .padding(.bottom, 4)

                HStack(spacing: 12) {
                    Text("Zoom:")
                    ForEach([1, 3, 6, 12, 24], id: \ .self) { hours in
                        Button("\(hours)h") {
                            zoomHours = hours
                        }
                        .buttonStyle(.bordered)
                        .tint(zoomHours == hours ? .blue : .gray)
                    }

                    Spacer()

                    Button("◀️") {
                        viewOffset += zoomHours
                    }

                    Button("▶️") {
                        viewOffset = max(0, viewOffset - zoomHours)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding()
    }
}
