//
//  ConversationLoader.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import Foundation
import GRDB
import SwiftUI
import XMTP

struct ConversationWithLastMessage: Codable, FetchableRecord {
	var conversation: DB.Conversation
	var lastMessage: DB.Message?
}

class ConversationLoader: ObservableObject {
	var client: XMTP.Client

	@MainActor @Published var error: Error?

	init(client: XMTP.Client) {
		self.client = client
	}

	func load() async throws {
		do {
			try await fetchRemote()
			try await fetchRecentMessages()
		} catch {
			await MainActor.run {
				self.error = error
			}
			print("Error in ConversationLoader.load(): \(error)")
		}
	}

	func fetchRemote() async throws {
		let conversations = try await client.conversations.list().map {
			try DB.Conversation.from($0)
		}

		let addresses = conversations.map(\.peerAddress)
		print("Got addresses: \(addresses)")

		do {
			let ensResults = try await ENS.shared.ens(addresses: addresses)
			print("Got ENS results: \(ensResults)")

			for conversation in conversations {
				var conversation = conversation

				if let result = ensResults[conversation.peerAddress.lowercased()], let result {
					conversation.ens = result
					try conversation.save()
				}
			}
		} catch {
			print("Error loading ENS: \(error)")
		}
	}

	func fetchRecentMessages() async throws {
		await withTaskGroup(of: Void.self) { group in
			for conversation in DB.Conversation.list() {
				group.addTask {
					do {
						var conversation = conversation
						print("Fetching most recent message for \(conversation.title)")
						try await conversation.loadMostRecentMessages(client: self.client)
						print("Done fetching most recent message for \(conversation.title)")
					} catch {
						print("Error loading most recent message for \(conversation.peerAddress): \(error)")
					}
				}
			}
		}
	}
}
