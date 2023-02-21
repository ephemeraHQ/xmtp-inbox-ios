//
//  SheetButton.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/20/23.
//

import SwiftUI

struct SheetButton<Content: View, SheetContent: View>: View {
	var label: () -> Content
	var sheetContent: () -> SheetContent

	@State private var isPresented: Bool = false

	var body: some View {
		Button(action: {
			isPresented.toggle()
		}) {
			label()
		}
		.sheet(isPresented: $isPresented) {
			sheetContent()
		}
	}
}
