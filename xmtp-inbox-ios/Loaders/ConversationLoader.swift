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
				.order(Column("updatedAt").desc)
				.group(Column("id"))
				.asRequest(of: ConversationWithLastMessage.self)
				.fetchAll(db)
		}.map {
			var conversation = $0.conversation
			conversation.lastMessage = $0.lastMessage
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

		let conversations = await conversations
		let addresses = conversations.map(\.peerAddress)
		do {
			let ensResults = try await ENS.shared.ens(addresses: addresses)

			for (i, conversation) in conversations.enumerated() {
				var conversation = conversation
				conversation.ens = ensResults[i]
				try conversation.save()
			}
		} catch {
			print("Error loading ENS: \(error)")
		}

//		// Reload view now that we have ENS names
		try await fetchLocal()
	}

	func fetchRecentMessages() async throws {
		await withTaskGroup(of: Void.self) { group in
			for conversation in await conversations {
				group.addTask {
					do {
						var conversation = conversation
						try await conversation.loadMostRecentMessage(client: self.client)
					} catch {
						print("Error loading most recent message for \(conversation.topic): \(error)")
					}
				}
			}
		}
	}
}
