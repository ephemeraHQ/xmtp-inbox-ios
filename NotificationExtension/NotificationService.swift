//
//  NotificationService.swift
//  NotificationService
//
//  Created by Pat Nakajima on 1/20/23.
//

import GRDB
import UserNotifications
import XMTP

class NotificationService: UNNotificationServiceExtension {
	var contentHandler: ((UNNotificationContent) -> Void)?
	var bestAttemptContent: UNMutableNotificationContent?

	override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
		self.contentHandler = contentHandler
		bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

		do {
			guard let encryptedMessage = request.content.userInfo["encryptedMessage"] as? String,
						let topic = request.content.userInfo["topic"] as? String,
						let encryptedMessageData = Data(base64Encoded: Data(encryptedMessage.utf8))
			else {
				print("Did not get correct message data from push")
				return
			}

			guard let keys = try Keystore.readKeys() else {
				print("DID NOT FIND KEYS")
				return
			}

			let client = try Client.from(v1Bundle: keys)
			print("GOT A CLIENT \(client)")

			guard let db = try DB.load(client: client), let conversationTopic = DB.ConversationTopic.using(db: db).find(Column("topic") == topic) else {
				return
			}

			let envelope = XMTP.Envelope.with { envelope in
				envelope.message = encryptedMessageData
				envelope.contentTopic = topic
			}

			if let bestAttemptContent = bestAttemptContent {
				let decodedMessage = try conversationTopic.toXMTP(client: client).decode(envelope)

				var conversation = DB.Conversation.using(db: db).find(id: conversationTopic.conversationID)

				// Don't notify when we're the sender
				if decodedMessage.senderAddress == client.address {
					contentHandler(UNNotificationContent())
					return
				}

				conversation?.updatedByPeerAt = decodedMessage.sent
				conversation?.updatedAt = decodedMessage.sent
				try conversation?.save(db: db)

				if let conversation {
					bestAttemptContent.title = conversation.title
				}
				bestAttemptContent.body = (try? decodedMessage.content()) ?? "no content"
				bestAttemptContent.threadIdentifier = conversationTopic.peerAddress

				contentHandler(bestAttemptContent)
			}
		} catch {
			print("Error receiving notification: \(error)")
		}
	}

	override func serviceExtensionTimeWillExpire() {
		print("serviceExtensionTimeWillExpire")
		// Called just before the extension will be terminated by the system.
		// Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
		if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
			contentHandler(bestAttemptContent)
		}
	}
}
