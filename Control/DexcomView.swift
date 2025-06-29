import SwiftUI

struct DexcomView: View {
    @StateObject private var dexcomClient = DexcomClient()
    @State private var now = Date()
    @State private var lastFetchTime: Date?
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    private var timeAgoText: String {
        guard let timestamp = dexcomClient.latestTimestamp else { return "—" }

        let minutesAgo = Int(now.timeIntervalSince(timestamp) / 60)
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        return "\(minutesAgo) min ago (\(formatter.string(from: timestamp)))"
    }
    
    private var lastRefreshText: String? {
        guard let fetchTime = lastFetchTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: fetchTime)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Latest BG")
                .font(.headline)
            
            if dexcomClient.latestTimestamp != nil {
                Text(timeAgoText)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            Text(dexcomClient.bgValue)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Previous: \(dexcomClient.previousBgValue)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Text(dexcomClient.trendArrow)
                    .font(.title2)
                Text(dexcomClient.rateOfChange)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let refreshText = lastRefreshText {
                Text("Refreshed at: \(refreshText)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

//            Button("Refresh") {
//                dexcomClient.loginAndFetch()
//            }
//            .padding(.top, 20)
        }
        .padding()
        .onAppear {
            dexcomClient.loginAndFetch()
        }
        .onReceive(timer) { _ in
            now = Date()
            dexcomClient.loginAndFetch()
            lastFetchTime = Date()
        }
    }
    
//    private func relativeDateString(from date: Date) -> String {
//        let formatter = RelativeDateTimeFormatter()
//        formatter.unitsStyle = .full
//        return formatter.localizedString(for: date, relativeTo: Date())
//    }
}
