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

	let fetchLimit = 10

	@MainActor @Published var mostRecentMessageID = ""
	@MainActor @Published var messages: [DB.Message] = []

	init(client: XMTP.Client, conversation: DB.Conversation) {
		self.client = client
		self.conversation = conversation

		do {
			try fetchLocal()
		} catch {
			print("Error fetching local messages: \(error)")
		}

		Task {
			await streamMessages()
		}
	}

	func streamMessages() async {
		for topic in conversation.topics() {
			Task {
				for try await xmtpMessage in try topic.toXMTP(client: client).streamMessages() {
					do {
						let message = try DB.Message.from(xmtpMessage, conversation: conversation, topic: topic)
						await MainActor.run {
							messages.append(message)
							mostRecentMessageID = message.xmtpID
						}
					} catch {
						print("Error with message: \(error)")
					}
				}
			}
		}
	}

	func load() async throws {
		try fetchLocal()
		try await fetchRemote()
	}

	func fetchRemote() async throws {
		for topic in conversation.topics() {
			do {
				let messages = try await topic.toXMTP(client: client).messages(limit: fetchLimit)
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

		try fetchLocal()
	}

	func fetchEarlier() async throws {
		let before = await MainActor.run { messages.first?.createdAt }

		for topic in conversation.topics() {
			do {
				let messages = try await topic.toXMTP(client: client).messages(limit: fetchLimit, before: before)
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

		try fetchLocal()
	}

	func fetchLocal() throws {
		let messages = try DB.shared.queue.read { db in
			try DB.Message
				.filter(Column("conversationID") == self.conversation.id)
				.order(Column("createdAt").asc)
				.fetchAll(db)
		}

		Task(priority: .userInitiated) {
			await MainActor.run {
				self.messages = messages
				self.mostRecentMessageID = messages.last?.xmtpID ?? ""
			}
		}
	}
}
