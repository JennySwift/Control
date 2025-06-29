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
            
            DispatchQueue.main.async {
                self.bgValue = formattedBG
                self.trendArrow = self.trendArrow(for: rateMMOLPerMin)
                self.rateOfChange = formattedRate
                self.latestTimestamp = time1
            }
        }
        
    }
}
