//
//  ConversationMessagesRequest.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/23/23.
//

import Combine
import GRDB
import GRDBQuery

struct ConversationMessagesRequest: Queryable {
	static var defaultValue: [DB.Message] { [] }

	var conversationID: Int

	func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[DB.Message], Error> {
		ValueObservation
			.tracking { db in
				do {
					return try DB.Message
						.filter(Column("conversationID") == conversationID)
						.order(Column("createdAt").asc)
						.fetchAll(db)
				} catch {
					fatalError("error in request: \(error)")
				}
			}
			// The `.immediate` scheduling feeds the view right on subscription,
			// and avoids an initial rendering with an empty list:
			.publisher(in: dbQueue, scheduling: .immediate)
			.eraseToAnyPublisher()
	}
}
