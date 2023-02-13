//
//  MessageLoader.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import Foundation
import GRDB
import SwiftUI
import XMTP

class MessageLoader: ObservableObject {
	var client: XMTP.Client
	var conversation: DB.Conversation

	@MainActor @Published var messages: [DB.Message] = []

	init(client: XMTP.Client, conversation: DB.Conversation) {
		self.client = client
		self.conversation = conversation

		Task {
			await streamMessages()
		}
	}

	func streamMessages() async {
		print("Stream messages called")
		for topic in conversation.topics() {
			Task {
				print("Listening on \(topic)")
				for try await xmtpMessage in try topic.toXMTP(client: client).streamMessages() {
					print("new xmtp message \(xmtpMessage)")
					do {
						let message = try DB.Message.from(xmtpMessage, conversation: conversation, topic: topic)
						print("got a message \(message)")
						await MainActor.run {
							messages.append(message)
						}
					} catch {
						print("Error with message: \(error)")
					}
				}
			}
		}
	}

	func load() async throws {
		try await fetchLocal()
		try await fetchRemote()
	}

	// TODO: paginate
	func fetchRemote() async throws {
		for topic in conversation.topics() {
			do {
				let messages = try await topic.toXMTP(client: client).messages()
				for message in messages {
					do {
						_ = try DB.Message.from(message, conversation: conversation, topic: topic)
					} catch {
						print("Error importing message: \(error)")
					}
				}
			} catch {
				print("Error loading messages for convo topic \(topic)")
			}
		}

		try await fetchLocal()
	}

	func fetchLocal() async throws {
		let messages = try await DB.read { db in
			try DB.Message
				.filter(Column("conversationID") == self.conversation.id)
				.order(Column("createdAt").asc)
				.fetchAll(db)
		}

		await MainActor.run {
			self.messages = messages
		}
	}
}
