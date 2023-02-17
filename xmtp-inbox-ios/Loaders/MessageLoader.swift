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

	@Published var mostRecentMessageID = ""
	@Published var messages: [DB.Message] = [] {
		didSet {
			Task { await regenerateTimeline() }
		}
	}

	@Published var timeline: [MessageListEntry] = []

	@MainActor init(client: XMTP.Client, conversation: DB.Conversation) {
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

	func streamTopic(topic: DB.ConversationTopic) async {
		do {
			for try await xmtpMessage in try topic.toXMTP(client: client).streamMessages() {
				let message = try DB.Message.from(xmtpMessage, conversation: conversation, topic: topic, isFromMe: client.address == xmtpMessage.senderAddress)
				await MainActor.run {
					messages.append(message)
					mostRecentMessageID = message.xmtpID
				}
			}
		} catch {
			print("Error streaming topic (\(topic)): \(error). Retrying…")
			await streamTopic(topic: topic)
		}
	}

	func streamMessages() async {
		for topic in conversation.topics() {
			Task {
				await streamTopic(topic: topic)
			}
		}
	}

	func load() async throws {
		try await fetchLocal()
		try await fetchRemote()
	}

	func fetchRemote() async throws {
		for topic in conversation.topics() {
			do {
				let messages = try await topic.toXMTP(client: client).messages(limit: fetchLimit)
				for message in messages {
					do {
						_ = try DB.Message.from(message, conversation: conversation, topic: topic, isFromMe: client.address == message.senderAddress)
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

	func fetchEarlier() async throws {
		let before = await MainActor.run { messages.first?.createdAt }

		for topic in conversation.topics() {
			do {
				let messages = try await topic.toXMTP(client: client).messages(limit: fetchLimit, before: before)
				for message in messages {
					do {
						_ = try DB.Message.from(message, conversation: conversation, topic: topic, isFromMe: client.address == message.senderAddress)
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

	@MainActor func fetchLocal() throws {
		let messages = try DB.read { db in
			try DB.Message
				.filter(Column("conversationID") == self.conversation.id)
				.order(Column("createdAt").asc)
				.fetchAll(db)
		}

		self.messages = messages
		mostRecentMessageID = messages.last?.xmtpID ?? ""
	}

	func regenerateTimeline() async {
		var result: [MessageListEntry] = []
		var lastTimestamp: Date?

		let timestampWindow: TimeInterval = 60 * 10 // 10 minutes

		// swiftlint:disable force_unwrapping
		for message in messages {
			if lastTimestamp != nil, message.createdAt > lastTimestamp!.addingTimeInterval(timestampWindow) {
				lastTimestamp = message.createdAt
				result.append(.timestamp(lastTimestamp!))
			} else if lastTimestamp == nil {
				lastTimestamp = message.createdAt
				result.append(.timestamp(lastTimestamp!))
			}

			result.append(.message(message))
		}
		// swiftlint:enable force_unwrapping

		let timeline = result
		await MainActor.run {
			self.timeline = timeline
		}
	}
}
