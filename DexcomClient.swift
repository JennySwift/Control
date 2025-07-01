//
//  DexcomClient.swift
//  Control
//
//  Created by Jenny Swift on 28/6/2025.
//

import Foundation

class DexcomClient: ObservableObject {
    @Published var bgValue: String = "Loading..."
    @Published var trendArrow: String = ""
    @Published var rateOfChange: String = ""
    @Published var latestTimestamp: Date?
    @Published var previousBgValue: String = ""
    @Published var recentReadings: [GlucoseReading] = []

    
    
    let username = Bundle.main.object(forInfoDictionaryKey: "DEXCOM_USERNAME") as? String ?? "MISSING_USERNAME"
    let password = Bundle.main.object(forInfoDictionaryKey: "DEXCOM_PASSWORD") as? String ?? "MISSING_PASSWORD"

    init() {
        print("USERNAME: \(username)")
        print("PASSWORD: \(password)")
    }
    
    private let applicationId = "d89443d2-327c-4a6f-89e5-496bbb0317db"
    private let baseURL = URL(string: "https://shareous1.dexcom.com/ShareWebServices/Services")!

    private var sessionId: String?

    func loginAndFetch() {
        Task {
            do {
                try await login()
                try await fetchLatestBG()
            } catch {
                DispatchQueue.main.async {
                    self.bgValue = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    //For the BG graph, because Apple Health BG data is 3 hours delayed.
    func fetchRecentReadings() {
        print("Started Dexcom fetchRecentReadings()")
        Task {
            do {
                try await login()
                try await fetchRecentBGReadings()
            } catch {
                print("Dexcom fetch error: \(error.localizedDescription)")
            }
        }
    }


    private func login() async throws {
        let url = URL(string: "\(baseURL)/General/LoginPublisherAccountByName")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(applicationId, forHTTPHeaderField: "applicationId")

        let body = [
            "accountName": username,
            "password": password,
            "applicationId": applicationId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        sessionId = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\"", with: "")
        print("✅ Logged in! Session ID: \(sessionId ?? "nil")")
    }
    
    private func trendArrow(for rate: Double) -> String {
        switch rate {
        case ..<(-0.10): return "⬇︎⬇︎"
        case -0.10..<(-0.05): return "↓"
        case -0.05..<(-0.025): return "↘︎"
        case -0.025...0.025: return "→"
        case 0.025..<0.05: return "↗︎"
        case 0.05..<0.10: return "↑"
        default: return "⬆︎⬆︎"
        }
    }
    
    private func parseDexcomDate(_ string: String) -> Date? {
        let pattern = #"Date\((\d+)\)"#
        if let match = string.range(of: pattern, options: .regularExpression) {
            let timestampString = String(string[match])
                .replacingOccurrences(of: "Date(", with: "")
                .replacingOccurrences(of: ")", with: "")
            if let millis = Double(timestampString) {
                return Date(timeIntervalSince1970: millis / 1000)
            }
        }
        return nil
    }

    private func fetchLatestBG() async throws {
        guard let sessionId = sessionId else { return }
        let url = URL(string: "\(baseURL)/Publisher/ReadPublisherLatestGlucoseValues?sessionId=\(sessionId)&minutes=30&maxCount=2")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(applicationId, forHTTPHeaderField: "applicationId")

        let (data, _) = try await URLSession.shared.data(for: request)
        if let readings = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           readings.count >= 2,
           let value1 = readings[0]["Value"] as? Int,
           let value2 = readings[1]["Value"] as? Int,
           let time1String = readings[0]["WT"] as? String,
           let time2String = readings[1]["WT"] as? String {

            let formatter = ISO8601DateFormatter()
            print("Raw WT values:", time1String, time2String)
            guard let time1 = parseDexcomDate(time1String),
                  let time2 = parseDexcomDate(time2String) else {
                DispatchQueue.main.async {
                    self.bgValue = "Error: Time parse"
                }
                return
            }

            let deltaMGDL = Double(value1 - value2)
            let deltaTimeMin = time1.timeIntervalSince(time2) / 60.0
            let rateMGDLPerMin = deltaMGDL / deltaTimeMin
            let rateMMOLPerMin = rateMGDLPerMin / 18.0

            let valueMMOL = Double(value1) / 18.0
            let formattedBG = String(format: "%.1f mmol/L", valueMMOL)
            let formattedRate = String(format: "%+.2f mmol/L/min", rateMMOLPerMin)
            let previousMMOL = Double(value2) / 18.0
            let formattedPrevious = String(format: "%.1f mmol/L", previousMMOL)
            
            DispatchQueue.main.async {
                self.bgValue = formattedBG
                self.trendArrow = self.trendArrow(for: rateMMOLPerMin)
                self.rateOfChange = formattedRate
                self.latestTimestamp = time1
                self.previousBgValue = formattedPrevious
            }
        }
        
    }
    
    private func fetchRecentBGReadings() async throws {
        guard let sessionId = sessionId else { return }
        let url = URL(string: "\(baseURL)/Publisher/ReadPublisherLatestGlucoseValues?sessionId=\(sessionId)&minutes=180&maxCount=36")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(applicationId, forHTTPHeaderField: "applicationId")

        let (data, _) = try await URLSession.shared.data(for: request)
        if let readings = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            let mapped = readings.compactMap { dict -> GlucoseReading? in
                guard let value = dict["Value"] as? Int,
                      let timeStr = dict["WT"] as? String,
                      let date = parseDexcomDate(timeStr) else { return nil }
                return GlucoseReading(value: Double(value) / 18.0, timestamp: date)
            }

            // Sort in DESCENDING order by timestamp (newest → oldest), then reverse to oldest → newest
            let sorted = mapped.sorted(by: { $0.timestamp > $1.timestamp }).reversed()

            if let first = sorted.first, let last = sorted.last {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .medium
                formatter.timeZone = TimeZone(identifier: "Australia/Sydney")
                print("📅 Dexcom BG range: \(formatter.string(from: first.timestamp)) → \(formatter.string(from: last.timestamp))")
            }

            DispatchQueue.main.async {
                self.recentReadings = Array(sorted)
            }
        }
    }


    //This worked for fetching readings but it didn't include readings from the most recent hour. Actually maybe that's because I'd just inserted a new sensor.
//    private func fetchRecentBGReadings() async throws {
//        guard let sessionId = sessionId else {
//                print("❌ No sessionId — login failed?")
//                return
//            }
//        let url = URL(string: "\(baseURL)/Publisher/ReadPublisherLatestGlucoseValues?sessionId=\(sessionId)&minutes=180&maxCount=100")!
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue(applicationId, forHTTPHeaderField: "applicationId")
//
//        let (data, _) = try await URLSession.shared.data(for: request)
//        if let readings = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
//            print("✅ Received \(readings.count) Dexcom readings")
//            let mapped = readings.compactMap { dict -> GlucoseReading? in
//                guard let value = dict["Value"] as? Int,
//                      let timeStr = dict["WT"] as? String,
//                      let date = parseDexcomDate(timeStr) else { return nil }
//                return GlucoseReading(value: Double(value) / 18.0, timestamp: date)
//            }
//            DispatchQueue.main.async {
//                self.recentReadings = mapped.sorted(by: { $0.timestamp < $1.timestamp })
//                if let first = self.recentReadings.first, let last = self.recentReadings.last {
//                        print("📅 Dexcom BG range: \(first.timestamp) → \(last.timestamp)")
//                    }
//            }
//        }
//    }

}
