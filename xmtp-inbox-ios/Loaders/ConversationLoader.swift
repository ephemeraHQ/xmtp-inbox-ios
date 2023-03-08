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
	var ensRefreshedAt: Date?
	var ensService: ENSService = ENS.shared

	@MainActor @Published var error: Error?

	init(client: XMTP.Client) {
		self.client = client
		self.ensRefreshedAt = (AppGroup.defaults.object(forKey: "ensRefreshedAt") as? Date)
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

		await refreshENS(conversations: conversations)
	}

	func fetchRecentMessages() async throws {
		await withTaskGroup(of: Void.self) { group in
			for conversation in DB.Conversation.list() {
				group.addTask {
					do {
						var conversation = conversation
						try await conversation.loadMostRecentMessages(client: self.client)
					} catch {
						print("Error loading most recent message for \(conversation.peerAddress): \(error)")
					}
				}
			}
		}
	}

	func refreshENS(conversations: [DB.Conversation]) async {
		if let ensRefreshedAt, ensRefreshedAt > Date().addingTimeInterval(-60 * 60) {
			return
		}

		let addresses = conversations.map(\.peerAddress)

		do {
			let ensResults = try await ensService.ens(addresses: addresses)

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
}
