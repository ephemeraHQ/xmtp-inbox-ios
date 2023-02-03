//
//  Message.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import GRDB
import XMTP

extension DB {
	struct Message {
		var id: Int?
		var xmtpID: String
		var body: String
		var conversationID: Int
		var senderAddress: String
		var createdAt: Date

		static func from(_ xmtpMessage: XMTP.DecodedMessage, conversation: Conversation) throws -> DB.Message {
			if let existing = DB.Message.find(Column("xmtpID") == xmtpMessage.id) {
				return existing
			}

			guard let conversationID = conversation.id else {
				throw Conversation.ConversationError.conversionError("no conversation ID")
			}

			var message = DB.Message(
				xmtpID: xmtpMessage.id,
				body: try xmtpMessage.content(),
				conversationID: conversationID,
				senderAddress: xmtpMessage.senderAddress,
				createdAt: xmtpMessage.sent
			)

			try message.save()

			return message
		}
	}
}

extension DB.Message: Model {
	static func createTable(db: GRDB.Database) throws {
		try db.create(table: "message", ifNotExists: true) { t in
			t.autoIncrementedPrimaryKey("id")
			t.column("xmtpID", .text).notNull().indexed()
			t.column("body", .text).notNull()
			t.column("conversationID", .integer).notNull().indexed()
			t.column("senderAddress", .text).notNull()
			t.column("createdAt", .date)
		}
	}
}
