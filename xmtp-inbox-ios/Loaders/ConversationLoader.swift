//
//  ConversationLoader.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import Foundation
import XMTP
import GRDB

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
			return try DB.Conversation
				.including(optional: DB.Conversation.lastMessage.forKey("lastMessage"))
				.fetchAll(db)
		}

		await MainActor.run {
			self.conversations = conversations
		}
	}

	func fetchRemote() async throws {
		let conversations = try await client.conversations.list().map { conversation in
			try DB.Conversation.from(conversation)
		}

		// Reload
		try await fetchLocal()
	}

	func fetchRecentMessages() async throws {
		print("--------- FETCHING RECENT MESSAGES \((await conversations).count)")
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
