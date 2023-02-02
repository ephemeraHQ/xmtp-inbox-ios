//
//  Conversation.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import GRDB
import XMTP

extension DB {
	struct Conversation {
		var id: Int?
		var topic: String
		var peerAddress: String
		var createdAt: Date

		init(id: Int? = nil, topic: String, peerAddress: String, createdAt: Date) {
			self.id = id
			self.topic = topic
			self.peerAddress = peerAddress
			self.createdAt = createdAt
		}

		static func from(_ xmtpConversation: XMTP.Conversation) throws -> DB.Conversation {
			var conversation = DB.Conversation.find(Column("topic") == xmtpConversation.topic) ?? DB.Conversation(
				topic: xmtpConversation.topic,
				peerAddress: xmtpConversation.peerAddress,
				createdAt: Date() // TODO: update
			)

			try conversation.save()

			return conversation
		}

		func send(text _: String) async throws {}

		public func streamMessages() -> AsyncThrowingStream<DecodedMessage, Error> {
			AsyncThrowingStream { _ in
			}
		}

		public func messages() async throws -> [DecodedMessage] {
			return []
		}
	}
}

extension DB.Conversation: Model {
	static func createTable(db: GRDB.Database) throws {
		try db.create(table: "conversation", ifNotExists: true) { t in
			t.autoIncrementedPrimaryKey("id")
			t.column("topic", .text).notNull().unique()
			t.column("peerAddress", .text).notNull().unique()
			t.column("createdAt", .date).notNull()
		}
	}
}
