//
//  GlucoseChartView.swift
//  Control
//
//  Created by Jenny Swift on 1/7/2025.
//

import HealthKit
import Foundation
import SwiftUI
import Charts

struct GlucoseChartView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var dexcomClient = DexcomClient()
    @State private var readings: [GlucoseReading] = []
    @State private var selectedReading: GlucoseReading? = nil
    @State private var zoomHours: Int = 24
    @State private var viewOffset: Int = 0
    @State private var targetLow: Double = 4.0
    @State private var targetHigh: Double = 10.0
    @State private var healthKitReadings: [GlucoseReading] = []


    private var zoomedReadings: [GlucoseReading] {
        let endDate = Calendar.current.date(byAdding: .hour, value: -viewOffset, to: Date()) ?? Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -zoomHours, to: endDate) ?? endDate
        return readings.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(
                selectedReading != nil
                ? "BG: \(String(format: "%.1f", selectedReading!.value)) at \(selectedReading!.timestamp.formatted(date: .omitted, time: .shortened))"
                : " "
            )
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .frame(width: 320)
            .multilineTextAlignment(.center)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        selectedReading?.value ?? 6 < targetLow ? Color.red.opacity(0.8) :
                        selectedReading?.value ?? 6 > targetHigh ? Color.yellow.opacity(0.8) :
                        Color.green.opacity(0.8)
                    )
            )
            .foregroundColor(
                selectedReading?.value ?? 6 > targetHigh ? .black : .white
            )
            .opacity(selectedReading == nil ? 0 : 1)
            .scaleEffect(selectedReading == nil ? 1.0 : 1.05)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedReading)





            if readings.isEmpty {
                ProgressView("Loading glucose data...")
                    .onAppear {
                        healthKitManager.requestAuthorization { success in
                            if success {
                                healthKitManager.fetchGlucoseData { healthData in
                                    self.healthKitReadings = healthData
                                    dexcomClient.fetchRecentReadings()
                                }
                            }
                        }
                    }
                    .onReceive(dexcomClient.$recentReadings) { newDexcomData in
                        print("Dexcom readings received: \(newDexcomData.count)")
                        print("🔁 Merging \(healthKitReadings.count) HealthKit + \(newDexcomData.count) Dexcom readings")
                        let merged = (healthKitReadings + newDexcomData)
                            .sorted(by: { $0.timestamp < $1.timestamp })
                        print("📊 Total merged readings: \(merged.count)")
                        self.readings = merged
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
                    // Bold red line at 4.0
                    RuleMark(y: .value("Low Target", targetLow))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                    // Bold yellow line at 10.0
                    RuleMark(y: .value("High Target", targetHigh))
                        .foregroundStyle(.yellow)
                        .lineStyle(StrokeStyle(lineWidth: 2))

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
                .chartYScale(domain: 4.0...(zoomedReadings.map(\.value).max() ?? 15))
                .frame(height: 300)
                .padding(.bottom, 4)

                HStack(spacing: 12) {
                    ForEach([1, 3, 6, 12, 24], id: \.self) { hours in
                        Button("\(hours)h") {
                            zoomHours = hours
                        }
                        .buttonStyle(.bordered)
                        .tint(zoomHours == hours ? .blue : .gray)
                    }
                }
                .font(.subheadline)
                
                HStack(spacing: 20) {
                    Button(action: {
                        viewOffset += zoomHours
                    }) {
                        Label("Earlier", systemImage: "arrow.left.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        viewOffset = max(0, viewOffset - zoomHours)
                    }) {
                        Label("Later", systemImage: "arrow.right.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 8)

            }
        }
        .padding()
    }
}
