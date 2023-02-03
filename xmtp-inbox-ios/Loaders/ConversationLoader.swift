//
//  ConversationLoader.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import Foundation
import GRDB
import XMTP

struct ConversationWithLastMessage: Codable, FetchableRecord {
	var conversation: DB.Conversation
	var lastMessage: DB.Message?
}

class ConversationLoader: ObservableObject {
	var client: XMTP.Client

	@MainActor @Published var conversations: [DB.Conversation] = []

	init(client: XMTP.Client) {
		self.client = client
	}

	func load() async throws {
		// Load stuff we already have in the DB...
		try await fetchLocal()

		// ...then fetch from the network...
		try await fetchRemote()

		// ...then refresh most recent messages...
		try await fetchRecentMessages()

		// Reload what we got from the db
		try await fetchLocal()
	}

	func fetchLocal() async throws {
		let conversations = try await DB.shared.queue.read { db in
			try DB.Conversation
				.including(optional: DB.Conversation.lastMessage.forKey("lastMessage"))
				.asRequest(of: ConversationWithLastMessage.self)
				.fetchAll(db)
		}.map { result in
			var conversation = result.conversation
			conversation.lastMessage = result.lastMessage
			return conversation
		}

		await MainActor.run {
			self.conversations = conversations
		}
	}

	func fetchRemote() async throws {
		for conversation in try await client.conversations.list() {
			try await DB.Conversation.from(conversation)
		}

		// Reload
		try await fetchLocal()
	}

	func fetchRecentMessages() async throws {
		for conversation in await conversations {
			var conversation = conversation

			do {
				try await conversation.loadMostRecentMessage(client: client)
			} catch {
				print("Error loading most recent message for \(conversation.topic): \(error)")
			}
		}
	}
}
