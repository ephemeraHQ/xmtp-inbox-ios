//
//  UpdatingRelativeTimestamp.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/23/23.
//

import SwiftUI

struct UpdatingRelativeTimestamp: View {
	var date: Date
	@State var formatted: String = ""

	init(_ date: Date) {
		self.date = date
		formatted = date.timeAgo
	}

	var body: some View {
		Text(formatted)
			.monospacedDigit()
			.id(date)
			.task {
				await update()
			}
	}

	func update() async {
		await MainActor.run {
			self.formatted = date.timeAgo
		}

		try? await Task.sleep(for: .seconds(5))

		await update()
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
