//
//  DexcomView.swift
//  Control
//
//  Created by Jenny Swift on 28/6/2025.
//

import SwiftUI

struct DexcomView: View {
    @StateObject private var dexcomClient = DexcomClient()

    var body: some View {
        VStack {
            Text("Current BG:")
                .font(.headline)
            Text(dexcomClient.bgReading)
                .font(.largeTitle)
                .padding()
            Button("Refresh") {
                dexcomClient.loginAndFetch()
            }
        }
        .onAppear {
            dexcomClient.loginAndFetch()
        }
    }
}
