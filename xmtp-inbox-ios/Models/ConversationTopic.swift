//
//  ConversationTopic.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/9/23.
//

import GRDB
import XMTP

extension DB {
	struct ConversationTopic: Model {
		enum Version: Codable {
			case v1, v2
		}

		static func createTable(db: GRDB.Database) throws {
			try db.create(table: "conversationTopic", ifNotExists: true) { t in
				t.autoIncrementedPrimaryKey("id").notNull().unique()
				t.column("conversationID", .integer).notNull().references("conversation")
				t.column("topic", .text).notNull().unique()
				t.column("peerAddress", .text).notNull()
				t.column("version", .blob).notNull()
				t.column("keyMaterial", .blob)
				t.column("contextData", .blob)
				t.column("createdAt", .date)
			}
		}

		var id: Int?
		var conversationID: Int
		var topic: String
		var peerAddress: String
		var createdAt: Date
		var keyMaterial: Data?
		var contextData: Data?
		var version: Version = .v2 // Default to v2

		var context: InvitationV1.Context? {
			guard let contextData else {
				return nil
			}

			do {
				return try InvitationV1.Context(serializedData: contextData)
			} catch {
				return nil
			}
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
					throw Conversation.ConversationError.conversionError("missing v2 fields")
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
