import SwiftUI

struct DexcomView: View {
    @StateObject private var dexcomClient = DexcomClient()
    @State private var now = Date()
    
    private var timeAgoText: String {
        guard let timestamp = dexcomClient.latestTimestamp else { return "—" }

        let minutesAgo = Int(now.timeIntervalSince(timestamp) / 60)
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        return "\(minutesAgo) min ago (\(formatter.string(from: timestamp)))"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Current BG")
                .font(.headline)

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
            
            if dexcomClient.latestTimestamp != nil {
                Text(timeAgoText)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            Button("Refresh") {
                dexcomClient.loginAndFetch()
            }
            .padding(.top, 20)
        }
        .padding()
        .onAppear {
            dexcomClient.loginAndFetch()
            startTimer()
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            now = Date()
        }
    }
    
    private func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
