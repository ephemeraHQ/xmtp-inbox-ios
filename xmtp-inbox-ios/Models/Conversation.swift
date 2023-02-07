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
			case conversionError(String)
		}

		enum Version: Codable {
			case v1, v2
		}

		var id: Int?
		var ens: String?
		var topic: String
		var peerAddress: String
		var createdAt: Date
		var updatedAt: Date
		var keyMaterial: Data?
		var contextData: Data?
		var version: Version = .v2 // Default to v2

		enum CodingKeys: String, CodingKey {
			case id, topic, ens, peerAddress, createdAt, updatedAt, keyMaterial, contextData, version
		}

		// Can be prefilled
		var lastMessage: DB.Message?

		init(id: Int? = nil, topic: String, peerAddress: String, createdAt: Date, updatedAt: Date? = nil) {
			self.id = id
			self.topic = topic
			self.peerAddress = peerAddress
			self.createdAt = createdAt
			self.updatedAt = updatedAt ?? createdAt
		}

		@discardableResult static func from(_ xmtpConversation: XMTP.Conversation) async throws -> DB.Conversation {
			var conversation = DB.Conversation.find(Column("topic") == xmtpConversation.topic) ?? DB.Conversation(
				topic: xmtpConversation.topic,
				peerAddress: xmtpConversation.peerAddress,
				createdAt: xmtpConversation.createdAt
			)

			if case let .v2(conversationV2) = xmtpConversation {
				conversation.version = Version.v2
				conversation.keyMaterial = conversationV2.keyMaterial
				conversation.contextData = try conversationV2.context.serializedData()
			} else {
				conversation.version = Version.v1
			}

			try conversation.save()

			return conversation
		}

		var title: String {
			ens ?? peerAddress.truncatedAddress()
		}

		mutating func loadMostRecentMessage(client: Client) async throws {
			guard let lastMessageXMTP = try await toXMTP(client: client).messages(limit: 1).first else {
				return
			}

			var lastMessage = try DB.Message.from(lastMessageXMTP, conversation: self)
			try lastMessage.save()

			updatedAt = lastMessage.createdAt
			try save()

			self.lastMessage = lastMessage
		}

		func toXMTP(client: Client) throws -> XMTP.Conversation {
			switch version {
			case .v1:
				return XMTP.Conversation.v1(
					XMTP.ConversationV1(
						client: client,
						peerAddress: peerAddress,
						sentAt: createdAt
					)
				)
			case .v2:
				guard let contextData, let keyMaterial else {
					throw ConversationError.conversionError("missing v2 fields")
				}

				let context = try InvitationV1.Context(serializedData: contextData)
				return XMTP.Conversation.v2(
					XMTP.ConversationV2(
						topic: topic,
						keyMaterial: keyMaterial,
						context: context,
						peerAddress: peerAddress,
						client: client
					)
				)
			}
		}
	}
}

extension DB.Conversation: Model {
	static func createTable(db: GRDB.Database) throws {
		try db.create(table: "conversation", ifNotExists: true) { t in
			t.autoIncrementedPrimaryKey("id")
			t.column("topic", .text).notNull().unique().indexed()
			t.column("ens", .text)
			t.column("peerAddress", .text).notNull().unique()
			t.column("createdAt", .date).notNull()
			t.column("updatedAt", .date).notNull()
			t.column("version", .blob).notNull()
			t.column("keyMaterial", .blob)
			t.column("contextData", .blob)
		}
	}

	// Associations
	static let lastMessage = hasOne(DB.Message.self, key: "id", using: ForeignKey(["conversationID"])).order(Column("createdAt").desc)
}
