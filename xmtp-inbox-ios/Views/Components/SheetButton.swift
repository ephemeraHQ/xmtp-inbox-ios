//
//  SheetButton.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/27/23.
//

import SwiftUI

struct SheetButton<LabelContent: View, SheetContent: View>: View {
	var label: () -> LabelContent
	var sheet: (@escaping () -> Void) -> SheetContent

	@State var isPresented = false

	var body: some View {
		Button(action: {
			isPresented.toggle()
		}) {
			label()
		}
		.sheet(isPresented: $isPresented) {
			sheet {
				self.isPresented = false
			}
		}
	}
}

struct SheetButton_Previews: PreviewProvider {
	static var previews: some View {
		SheetButton(label: { Text("Label") }, sheet: { _ in Text("Sheet") })
	}
}
