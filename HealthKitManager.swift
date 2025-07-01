
// HealthKitManager.swift
// Fetch Dexcom CGM data from Apple Health (last 3 days)

import HealthKit
import Foundation
import SwiftUI
import Charts

struct GlucoseReading: Identifiable, Equatable {
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
        //Because Apple Health BG is 3 hours delayed, we get the most recent 3 hours of data from Dexcom instead of Apple Health.
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: -3, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: cutoffDate, options: [])

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


