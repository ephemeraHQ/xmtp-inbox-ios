//
//  MessageLoader.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import Foundation
import GRDB
import XMTP

class MessageLoader: ObservableObject {
	var client: XMTP.Client
	var conversation: DB.Conversation

	@MainActor @Published var messages: [DB.Message] = []

	init(client: XMTP.Client, conversation: DB.Conversation) {
		self.client = client
		self.conversation = conversation
	}

	func load() async throws {
		try await fetchLocal()
	}

	func fetchLocal() async throws {
		let messages = try await DB.shared.queue.read { db in
			try DB.Message
				.filter(Column("conversationID") == self.conversation.id)
				.order(Column("createdAt").desc)
				.fetchAll(db)
		}

		await MainActor.run {
			self.messages = messages
		}
	}
}
