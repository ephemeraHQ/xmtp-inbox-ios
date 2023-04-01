//
//  DBProvider.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 3/13/23.
//

import GRDB
import SwiftUI
import XMTP

struct DBProvider<Content: View>: View {
	var client: XMTP.Client
	var content: () -> Content

	@State private var db: DB?
	@State private var dbQueue: DatabaseQueue?

	var body: some View {
		if let db {
			content()
				.environment(\.db, db)
				.environment(\.dbQueue, db.queue)
		} else {
			ProgressView("Preparing database…")
				.onAppear {
					do {
						if let db = try? DB.load(client: client) {
							self.db = db
						} else {
							self.db = try DB.prepare(client: client, reset: true)
						}
					} catch {
						print("Error preparing db: \(error)")
					}
				}
		}
	}
}

struct DBQueueProvider_Previews: PreviewProvider {
	static var previews: some View {
		PreviewClientProvider { client in
			DBProvider(client: client) {
				Text("Hi")
			}
		}
	}
}
