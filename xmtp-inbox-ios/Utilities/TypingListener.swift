//
//  TypingListener.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 3/27/23.
//

import Foundation
import XMTP
import Combine

class TypingListener: ObservableObject {
	@Published var isTyping = false
	@Published var lastTypedAt: Date?
	@Published var lastMessageSentAt: Date?
	var publisher = PassthroughSubject<TypingNotification?, Never>()
	var cancellable: AnyCancellable?

	struct Message: Codable {
		var kind: String
		var sender: String
		var topic: String
		var timestamp: Date
	}

	var client: Client
	var conversation: XMTP.Conversation
	var error: Error?

	init(client: Client, conversation: XMTP.Conversation) {
		self.client = client
		self.conversation = conversation

		Task {
			self.cancellable = publisher.debounce(
				for: .seconds(0.5),
				scheduler: DispatchQueue.main
			).sink { notification in
				if let notification {
					if notification.typerAddress == conversation.clientAddress {
						return
					}

					if notification.isFinished {
						self.lastMessageSentAt = notification.timestamp
						self.isTyping = false
						return
					}

					self.lastTypedAt = notification.timestamp

					if let lastMessageSentAt = self.lastMessageSentAt, let lastTypedAt = self.lastTypedAt {
						print("First \(lastMessageSentAt < lastTypedAt)")
						self.isTyping = lastMessageSentAt < lastTypedAt
					} else {
						print("is typing is true")
						self.isTyping = true
					}

					Task {
						try? await Task.sleep(for: .seconds(1))
						await MainActor.run {
							self.publisher.send(nil)
						}
					}
				} else {
					self.isTyping = false
				}
			}
		}
	}

	func stream() async throws {
		guard let stream = conversation.streamEphemeral() else {
			return
		}

		for try await envelope in stream {
			if let message = try? conversation.decode(envelope) {
				try? handle(message: message)
			}
		}
	}

	func handle(message: DecodedMessage) throws {
		if message.encodedContent.type != ContentTypeTypingNotification {
			return
		}

		publisher.send(try message.content())
	}
}
