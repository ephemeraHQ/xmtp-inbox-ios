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
		var conversationTopicID: Int
		var senderAddress: String
		var createdAt: Date
		var isFromMe: Bool

		init(id: Int? = nil, xmtpID: String, body: String, conversationID: Int, conversationTopicID: Int, senderAddress: String, createdAt: Date, isFromMe: Bool) {
			self.id = id
			self.xmtpID = xmtpID
			self.body = body
			self.conversationID = conversationID
			self.conversationTopicID = conversationTopicID
			self.senderAddress = senderAddress
			self.createdAt = createdAt
			self.isFromMe = isFromMe
		}

		@discardableResult static func from(_ xmtpMessage: XMTP.DecodedMessage, conversation: Conversation, topic: ConversationTopic, isFromMe: Bool) throws -> DB.Message {
			if let existing = DB.Message.find(Column("xmtpID") == xmtpMessage.id) {
				return existing
			}

			guard let conversationID = conversation.id, let topicID = topic.id else {
				throw Conversation.ConversationError.conversionError("no conversation ID")
			}

			if xmtpMessage.id == "" {
				throw DBError.badData("Missing XMTP ID")
			}

			var message = DB.Message(
				xmtpID: xmtpMessage.id,
				body: try xmtpMessage.content(),
				conversationID: conversationID,
				conversationTopicID: topicID,
				senderAddress: xmtpMessage.senderAddress,
				createdAt: xmtpMessage.sent,
				isFromMe: isFromMe
			)

			try message.save()
			try message.updateConversationTimestamps(conversation: conversation)

			return message
		}

		func updateConversationTimestamps(conversation: DB.Conversation) throws {
			var conversation = conversation

			if createdAt > conversation.updatedAt {
				conversation.updatedAt = createdAt
			}

			if isFromMe {
				try conversation.save()
				return
			}

			if conversation.updatedByPeerAt == nil {
				conversation.updatedByPeerAt = createdAt
			} else if let updatedByPeerAt = conversation.updatedByPeerAt, updatedByPeerAt < createdAt {
				conversation.updatedByPeerAt = createdAt
			}

			try conversation.save()
		}
	}
}

extension DB.Message: Model {
	static func createTable(db: GRDB.Database) throws {
		try db.create(table: "message", ifNotExists: true) { t in
			t.autoIncrementedPrimaryKey("id")
			t.column("xmtpID", .text).notNull().indexed().unique()
			t.column("body", .text).notNull()
			t.column("conversationID", .integer).notNull().indexed()
			t.column("conversationTopicID", .integer).notNull().indexed()
			t.column("senderAddress", .text).notNull()
			t.column("createdAt", .date)
			t.column("isFromMe", .boolean).notNull()
		}
	}
}

extension DB.Message {
	static var preview: DB.Message {
		DB.Message(xmtpID: "aslkdjfalksdljkafsdjasf", body: "hello there", conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
	}
}
