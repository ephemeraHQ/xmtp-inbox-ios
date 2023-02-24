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
				let conversations = try DB.Conversation
					.order(Column("updatedAt").desc)
					.group(Column("id"))
					.fetchAll(db)

				let mostRecentMessages = try DB.Message
					.select(AllColumns(), max(Column("createdAt")))
					.group(Column("conversationID"))
					.order(Column("id").desc)
					.fetchAll(db)

				let mostRecentMessagesByConversationID = mostRecentMessages.reduce([Int: DB.Message]()) { res, message in
					var res = res
					res[message.conversationID] = message
					return res
				}

				let conversationsWithMostRecentMessages = conversations.map {
					var conversation = $0

					if let conversationID = conversation.id {
						conversation.lastMessage = mostRecentMessagesByConversationID[conversationID]
					}

					return conversation
				}

				return conversationsWithMostRecentMessages
			}
			// The `.immediate` scheduling feeds the view right on subscription,
			// and avoids an initial rendering with an empty list:
			.publisher(in: dbQueue, scheduling: .immediate)
			.removeDuplicates()
			.eraseToAnyPublisher()
	}
}
