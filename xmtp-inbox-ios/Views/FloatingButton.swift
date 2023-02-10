//
//  FloatingButton.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 2/8/23.
//

import SwiftUI

struct FloatingButton: View {
	var icon: Image
	var action: () -> Void

	var body: some View {
		HapticButton(action: {
			action()
		}) {
			icon
		}
		.frame(width: 48, height: 48)
		.background(Color.actionPrimary)
		.foregroundColor(.actionPrimaryText)
		.clipShape(Circle())
		.shadow(radius: 2, x: 0, y: 1)
	}
}
