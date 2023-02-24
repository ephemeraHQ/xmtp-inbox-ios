//
//  ConversationsRequest.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/23/23.
//
import Combine
import GRDB
import GRDBQuery

struct ConversationsRequest: Queryable {
	static var defaultValue: [DB.Conversation] { [] }

	func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[DB.Conversation], Error> {
		ValueObservation
			.tracking { db in
				do {
					//				try DB.Conversation.fetchAll(db)
					return try DB.Conversation
						.including(optional: DB.Conversation.lastMessage.forKey("lastMessage"))
						.order(Column("updatedAt").desc)
						.group(Column("id"))
						.asRequest(of: ConversationWithLastMessage.self)
						.fetchAll(db)
						.map {
							var conversation = $0.conversation
							conversation.lastMessage = $0.lastMessage
							return conversation
						}
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
