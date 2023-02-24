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
	var messages: [DB.Message] = []

	init(client: XMTP.Client, conversation: DB.Conversation) {
		self.client = client
		self.conversation = conversation
	}

	func streamTopic(topic: DB.ConversationTopic) async {
		do {
			for try await xmtpMessage in try topic.toXMTP(client: client).streamMessages() {
				let message = try await DB.Message.from(xmtpMessage, conversation: conversation, topic: topic, isFromMe: client.address == xmtpMessage.senderAddress)
				await MainActor.run {
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
		try await fetchRemote()
	}

	func fetchRemote() async throws {
		for topic in conversation.topics() {
			do {
				let messages = try await topic.toXMTP(client: client).messages(limit: fetchLimit)
				for message in messages {
					do {
						_ = try await DB.Message.from(message, conversation: conversation, topic: topic, isFromMe: client.address == message.senderAddress)
					} catch {
						print("Error importing message: \(error)")
					}
				}
			} catch {
				print("Error loading messages for convo topic \(topic)")
			}
		}
	}

	func fetchEarlier() async throws {
		let before = await MainActor.run { messages.first?.createdAt }

		for topic in conversation.topics() {
			do {
				let messages = try await topic.toXMTP(client: client).messages(limit: fetchLimit, before: before)
				for message in messages {
					do {
						_ = try await DB.Message.from(message, conversation: conversation, topic: topic, isFromMe: client.address == message.senderAddress)
					} catch {
						print("Error importing message: \(error)")
					}
				}
			} catch {
				print("Error loading messages for convo topic \(topic)")
			}
		}
	}
}
