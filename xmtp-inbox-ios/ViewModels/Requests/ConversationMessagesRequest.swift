//
//  ConversationMessagesRequest.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/23/23.
//

import Combine
import GRDB
import GRDBQuery

struct MessageWithAttachments: Codable, FetchableRecord {
	var message: DB.Message
	var remoteAttachments: [DB.RemoteAttachment]
	var attachments: [DB.MessageAttachment]
}

struct ConversationMessagesRequest: Queryable {
	static var defaultValue: [DB.Message] { [] }

	var conversationID: Int

	func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[DB.Message], Error> {
		ValueObservation
			.tracking { db in
				do {
					let messages = try DB.Message
						.filter(Column("conversationID") == conversationID)
						.order(Column("createdAt").asc)
						.fetchAll(db)

					let messageAttachments = try DB.MessageAttachment.filter(messages.map(\.id).contains(Column("messageID"))).fetchAll(db).reduce([Int: [DB.MessageAttachment]]()) { res, messageAttachment in
						var res = res
						var list = res[messageAttachment.messageID] ?? []
						list.append(messageAttachment)
						res[messageAttachment.messageID] = list
						return res
					}

					let remoteAttachments = try DB.RemoteAttachment.filter(messages.map(\.id).contains(Column("messageID"))).fetchAll(db).reduce([Int: [DB.RemoteAttachment]]()) { res, remoteAttachment in
						var res = res
						var list = res[remoteAttachment.messageID] ?? []
						list.append(remoteAttachment)
						res[remoteAttachment.messageID] = list
						return res
					}

					return messages.map { message in
						var message = message
						message.remoteAttachments = remoteAttachments[message.id ?? 0] ?? []
						message.attachments = messageAttachments[message.id ?? 0] ?? []
						return message
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
