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

			try DB.shared.prepare(passphrase: "make this real", reset: false)

			guard let conversationTopic = DB.ConversationTopic.find(Column("topic") == topic) else {
				return
			}

			guard let keys = try Keystore.readKeys() else {
				return
			}

			let client = try Client.from(v1Bundle: keys)

			let envelope = XMTP.Envelope.with { envelope in
				envelope.message = encryptedMessageData
				envelope.contentTopic = topic
			}

			if let bestAttemptContent = bestAttemptContent {
				let decodedMessage = try conversationTopic.toXMTP(client: client).decode(envelope)

				if let conversation = DB.Conversation.find(id: conversationTopic.conversationID) {
					bestAttemptContent.title = "New message from \(conversation.title)"
				}
				bestAttemptContent.body = (try? decodedMessage.content()) ?? "no content"

				contentHandler(bestAttemptContent)
			}

			// swiftlint:enable no_optional_try
		} catch {
			print("Error receiving notification: \(error)")
		}
	}

	override func serviceExtensionTimeWillExpire() {
		// Called just before the extension will be terminated by the system.
		// Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
		if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
			contentHandler(bestAttemptContent)
		}
	}
}
