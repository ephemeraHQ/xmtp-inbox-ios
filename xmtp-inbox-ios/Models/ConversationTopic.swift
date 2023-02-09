//
//  ConversationTopic.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/9/23.
//

import GRDB

extension DB {
	struct ConversationTopic: Model {
		static func createTable(db: GRDB.Database) throws {
			try db.create(table: "conversationTopic") { t in
				t.autoIncrementedPrimaryKey("id").notNull().unique()
				t.column("topic", .text).notNull().unique()
				t.column("peerAddress", .text).notNull().unique()
			}
		}

		var id: Int?
		var topic: String
		var peerAddress: String
	}
}
