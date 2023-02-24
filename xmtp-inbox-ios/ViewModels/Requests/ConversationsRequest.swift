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
					let conversations = try DB.Conversation
						.order(Column("updatedAt").desc)
						.group(Column("id"))
						.fetchAll(db)

					let mostRecentMessages = try DB.Message
						.order(Column("createdAt").desc)
						.group(Column("conversationID"))
						.fetchAll(db)
						.reduce([Int: DB.Message]()) { res, message in
							var res = res
							res[message.conversationID] = message
							return res
						}

					let conversationsWithMostRecentMessages = conversations.map {
						var conversation = $0

						if let conversationID = conversation.id {
							conversation.lastMessage = mostRecentMessages[conversationID]
						}

						return conversation
					}

					return conversationsWithMostRecentMessages
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
