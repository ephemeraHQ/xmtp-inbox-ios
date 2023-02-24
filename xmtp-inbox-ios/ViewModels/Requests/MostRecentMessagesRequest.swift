//
//  MostRecentMessagesRequest.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/23/23.
//

import Combine
import GRDB
import GRDBQuery

struct MostRecentMessagesRequest: Queryable {
	static var defaultValue: [Int: DB.Message] { [:] }

	func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[Int: DB.Message], Error> {
		ValueObservation
			.tracking { db in
				do {
					return try DB.Message
						.order(Column("createdAt").desc)
						.group(Column("conversationID"))
						.fetchAll(db)
						.reduce([Int: DB.Message]()) { res, message in
							var res = res

							res[message.conversationID] = message

							return res
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
