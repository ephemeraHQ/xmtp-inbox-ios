//
//  Conversation.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import Foundation
import GRDB
import XMTP

extension DB {
	struct Conversation: Codable {
		enum ConversationError: Error {
			case conversionError(String), noTopic, noID
		}

		var id: Int?
		var ens: String?
		var peerAddress: String
		var createdAt: Date
		var updatedAt: Date

		// Fields for unread state
		var viewedAt: Date?
		var updatedByPeerAt: Date?

		enum CodingKeys: String, CodingKey {
			case id, ens, peerAddress, createdAt, updatedAt, viewedAt, updatedByPeerAt
		}

		// Can be prefilled
		var lastMessage: DB.Message?

		init(id: Int? = nil, peerAddress: String, createdAt: Date, updatedAt: Date? = nil, viewedAt: Date? = nil) {
			self.id = id
			self.peerAddress = peerAddress
			self.createdAt = createdAt
			self.updatedAt = updatedAt ?? createdAt
			self.viewedAt = viewedAt
		}

		@discardableResult static func from(_ xmtpConversation: XMTP.Conversation) async throws -> DB.Conversation {
			do {
				if let conversation = DB.Conversation.find(Column("peerAddress") == xmtpConversation.peerAddress) {
					try conversation.createTopic(from: xmtpConversation)

					return conversation
				}

				var conversation = DB.Conversation(
					peerAddress: xmtpConversation.peerAddress,
					createdAt: xmtpConversation.createdAt
				)

				try conversation.save()
				try conversation.createTopic(from: xmtpConversation)

				Task {
					try await XMTPPush.shared.subscribe(topics: [xmtpConversation.topic])
				}

				return conversation
			} catch {
				print("ERROR Conversation.from \(error)")
				throw error
			}
		}

		@discardableResult func createTopic(from xmtpConversation: XMTP.Conversation) throws -> ConversationTopic {
			if let topic = DB.ConversationTopic.find(Column("topic") == xmtpConversation.topic) {
				return topic
			}

			guard let id else {
				throw ConversationError.noID
			}

			var conversationTopic = DB.ConversationTopic(conversationID: id, topic: xmtpConversation.topic, peerAddress: xmtpConversation.peerAddress, createdAt: xmtpConversation.createdAt)

			if case let .v2(conversationV2) = xmtpConversation {
				conversationTopic.version = .v2
				conversationTopic.keyMaterial = conversationV2.keyMaterial
				conversationTopic.contextData = try conversationV2.context.serializedData()
			} else {
				conversationTopic.version = .v1
			}

			try conversationTopic.save()

			return conversationTopic
		}

		var title: String {
			ens ?? peerAddress.truncatedAddress()
		}

		mutating func markViewed() {
			do {
				viewedAt = Date()
				try save()
			} catch {
				print("Error marking conversation viewed: \(error)")
			}
		}

		func messages(client: Client) async throws -> [DecodedMessage] {
			var messages: [DecodedMessage] = []

			for topic in topics() {
				messages.append(contentsOf: try await topic.toXMTP(client: client).messages())
			}

			return messages
		}

		mutating func loadMostRecentMessage(client: Client) async throws {
			for topic in topics() {
				guard let lastMessageXMTP = try await topic.toXMTP(client: client).messages(limit: 1).first else {
					return
				}

				try await DB.Message.from(lastMessageXMTP, conversation: self, topic: topic, isFromMe: client.address == lastMessageXMTP.senderAddress)
			}

			let lastMessage = try DB.read { db in
				try DB.Message.filter(Column("conversationID") == id).order(Column("createdAt").desc).fetchOne(db)
			}

			guard let lastMessage else {
				return
			}

			updatedAt = lastMessage.createdAt
			try save()

			self.lastMessage = lastMessage
		}

		func send(text: String, client: Client, topic: ConversationTopic? = nil) async throws {
			guard let topic = topic ?? topics().last, let topicID = topic.id else {
				throw ConversationError.noTopic
			}

			let messageID = try await topic.toXMTP(client: client).send(text: text)

			try await MainActor.run {
				var message = DB.Message(xmtpID: messageID, body: text, conversationID: topic.conversationID, conversationTopicID: topicID, senderAddress: topic.peerAddress, createdAt: Date(), isFromMe: true)
				try message.save()
			}
		}

		func topics() -> [ConversationTopic] {
			do {
				return try DB.read { db in
					try DB.ConversationTopic.filter(Column("conversationID") == id).fetchAll(db)
				}
			} catch {
				print("Error loading topics for conversation: \(self) \(error)")
				return []
			}
		}
	}
}

extension DB.Conversation: Model {
	static func createTable(db: GRDB.Database) throws {
		try db.create(table: "conversation", ifNotExists: true) { t in
			t.autoIncrementedPrimaryKey("id")
			t.column("ens", .text)
			t.column("peerAddress", .text).notNull()
			t.column("createdAt", .date).notNull()
			t.column("updatedAt", .date).notNull()
			t.column("viewedAt", .date)
			t.column("updatedByPeerAt", .date)
		}
	}

	// Associations
	static let lastMessage = hasOne(DB.Message.self, key: "id", using: ForeignKey(["conversationID"])).select(AllColumns(), max(Column("createdAt")))
}
