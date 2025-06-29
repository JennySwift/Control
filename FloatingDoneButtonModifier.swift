//
//  FloatingDoneButtonModifier.swift
//  Control
//
//  Created by Jenny Swift on 29/6/2025.
//

import SwiftUI

struct FloatingDoneButtonModifier<Value: Hashable>: ViewModifier {
    var focusedField: FocusState<Value?>.Binding

    func body(content: Content) -> some View {
        ZStack(alignment: .bottomTrailing) {
            content
            if focusedField.wrappedValue != nil {
                Button(action: {
                    focusedField.wrappedValue = nil
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                        .padding([.bottom, .trailing], 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: focusedField.wrappedValue)
            }
        }
    }
}

extension View {
    func floatingDoneButton<Value: Hashable>(focusedField: FocusState<Value?>.Binding) -> some View {
        self.modifier(FloatingDoneButtonModifier(focusedField: focusedField))
    }
}
