//
//  DBQueueProvider.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 3/13/23.
//

import GRDB
import SwiftUI

struct DBQueueProvider<Content: View>: View {
	var content: () -> Content

	@State private var dbQueue: DatabaseQueue?

	var body: some View {
		if let dbQueue {
			content()
				.environment(\.dbQueue, dbQueue)
		} else {
			ProgressView()
				.task {
					let queue = await DB._queue
					print("Updated queue")
					await MainActor.run {
						self.dbQueue = queue
					}
				}
		}
	}
}

struct DBQueueProvider_Previews: PreviewProvider {
	static var previews: some View {
		DBQueueProvider {
			Text("Hi")
		}
	}
}
