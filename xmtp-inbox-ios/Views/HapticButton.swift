//
//  HapticButtonView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 2/1/23.
//

import SwiftUI

struct HapticButton<Content: View>: View {
    var action: () -> Void
    @ViewBuilder var label: () -> Content

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            action()
        }) {
            label()
        }
    }
}
