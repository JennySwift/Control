//
//  DexcomClient.swift
//  Control
//
//  Created by Jenny Swift on 28/6/2025.
//

import Foundation

class DexcomClient: ObservableObject {
    @Published var bgReading: String = "Loading..."
    
    let username = Bundle.main.object(forInfoDictionaryKey: "DEXCOM_USERNAME") as? String ?? "MISSING_USERNAME"
    let password = Bundle.main.object(forInfoDictionaryKey: "DEXCOM_PASSWORD") as? String ?? "MISSING_PASSWORD"

    init() {
        print("USERNAME: \(username)")
        print("PASSWORD: \(password)")
        
        let username = ProcessInfo.processInfo.environment["DEXCOM_USERNAME"] ?? "MISSING_USERNAME"
        let password = ProcessInfo.processInfo.environment["DEXCOM_PASSWORD"] ?? "MISSING_PASSWORD"

        print("USERNAME:", username)
        print("PASSWORD:", password)
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
                    self.bgReading = "Error: \(error.localizedDescription)"
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

    private func fetchLatestBG() async throws {
        guard let sessionId = sessionId else { return }
        let url = URL(string: "\(baseURL)/Publisher/ReadPublisherLatestGlucoseValues?sessionId=\(sessionId)&minutes=1440&maxCount=1")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(applicationId, forHTTPHeaderField: "applicationId")

        let (data, _) = try await URLSession.shared.data(for: request)
        if let readings = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let value = readings.first?["Value"] as? Int {
            DispatchQueue.main.async {
                let mmol = Double(value) / 18.0
                self.bgReading = String(format: "%.1f mmol/L", mmol)
            }
        }
    }
}
