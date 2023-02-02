//
//  ConversationLoader.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import Foundation
import XMTP

class ConversationLoader: ObservableObject {
	var client: XMTP.Client

	@MainActor @Published var conversations: [DB.Conversation] = []

	init(client: XMTP.Client) {
		self.client = client
	}

	func loadInitial() async throws {
		let conversations = DB.Conversation.list()

		await MainActor.run {
			self.conversations = conversations
		}
	}

	func fetchInitial() async throws {
		let conversations = try await client.conversations.list()
		let dbConversations = try conversations.map { try DB.Conversation.from($0) }
		await MainActor.run {
			self.conversations = dbConversations
		}
	}
}
