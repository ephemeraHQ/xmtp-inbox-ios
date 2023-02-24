//
//  UpdatingRelativeTimestamp.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/23/23.
//

import SwiftUI

struct UpdatingRelativeTimestamp: View {
	let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
	var date: Date
	@State var formatted: String?

	init(_ date: Date) {
		self.date = date
	}

	var body: some View {
		Text(formatted ?? date.timeAgo)
			.monospacedDigit()
			.onReceive(timer) { _ in
				formatted = date.timeAgo
			}
	}
}

struct UpdatingRelativeTimestampPreviewContainer: View {
	var date = Date()

	var body: some View {
		UpdatingRelativeTimestamp(date)
	}
}

struct UpdatingRelativeTimestamp_Previews: PreviewProvider {
	static var previews: some View {
		UpdatingRelativeTimestampPreviewContainer()
	}
}
