import SwiftUI

struct DexcomView: View {
    @StateObject private var dexcomClient = DexcomClient()

    var body: some View {
        VStack(spacing: 16) {
            Text("Current BG")
                .font(.headline)

            Text(dexcomClient.bgValue)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.primary)

            HStack(spacing: 10) {
                Text(dexcomClient.trendArrow)
                    .font(.title2)
                Text(dexcomClient.rateOfChange)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Button("Refresh") {
                dexcomClient.loginAndFetch()
            }
            .padding(.top, 20)
        }
        .padding()
        .onAppear {
            dexcomClient.loginAndFetch()
        }
    }
}
