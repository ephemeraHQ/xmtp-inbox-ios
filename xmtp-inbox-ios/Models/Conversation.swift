//
//  Conversation.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import GRDB

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
