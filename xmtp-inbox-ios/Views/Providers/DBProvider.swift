//
//  DBProvider.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 3/13/23.
//

import GRDB
import XMTP
import SwiftUI

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
//						self.db = try DB.prepare(client: client)
						self.db = try DB.load(client: client)
					} catch {
//						self.db = try! DB.prepare(client: client, reset: true)
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
