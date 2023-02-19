//
//  Message.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import GRDB
import OpenGraph
import SwiftUI
import XMTP

extension DB {
	struct Message {
		var id: Int?
		var xmtpID: String
		var body: String
		var conversationID: Int
		var conversationTopicID: Int
		var senderAddress: String
		var createdAt: Date
		var isFromMe: Bool
		var previewData: Data?

		// Cached images
		var image: Image?
		var animatedImage: Data?

		enum CodingKeys: String, CodingKey {
			case id, xmtpID, body, conversationID, conversationTopicID, senderAddress, createdAt, isFromMe, previewData
		}

		init(id: Int? = nil, xmtpID: String, body: String, conversationID: Int, conversationTopicID: Int, senderAddress: String, createdAt: Date, isFromMe: Bool) {
			self.id = id
			self.xmtpID = xmtpID
			self.body = body
			self.conversationID = conversationID
			self.conversationTopicID = conversationTopicID
			self.senderAddress = senderAddress
			self.createdAt = createdAt
			self.isFromMe = isFromMe
		}

		var isBareImageURL: Bool {
			if body.isValidURL, let url = URL(string: body), ["jpg", "jpeg", "png", "gif", "webp"].contains(url.pathExtension) {
				return true
			}

			return false
		}

		var preview: URLPreview?
		mutating func loadPreview() {
			if preview != nil {
				return
			}

			guard let previewData else {
				return
			}

			do {
				let decoder = JSONDecoder()
				let preview = try decoder.decode(URLPreview.self, from: previewData)

				self.preview = preview
			} catch {
				print("Error loading preview: \(error)")
			}
		}

		@discardableResult static func from(_ xmtpMessage: XMTP.DecodedMessage, conversation: Conversation, topic: ConversationTopic, isFromMe: Bool) async throws -> DB.Message {
			if let existing = DB.Message.find(Column("xmtpID") == xmtpMessage.id) {
				return existing
			}

			guard let conversationID = conversation.id, let topicID = topic.id else {
				throw Conversation.ConversationError.conversionError("no conversation ID")
			}

			if xmtpMessage.id == "" {
				throw DBError.badData("Missing XMTP ID")
			}

			var message = DB.Message(
				xmtpID: xmtpMessage.id,
				body: try xmtpMessage.content(),
				conversationID: conversationID,
				conversationTopicID: topicID,
				senderAddress: xmtpMessage.senderAddress,
				createdAt: xmtpMessage.sent,
				isFromMe: isFromMe
			)

			if Settings.shared.showLinkPreviews,
			   message.body.isValidURL,
			   let url = URL(string: message.body),
			   // swiftlint:disable no_optional_try
			   let og = try? await OpenGraph.fetch(url: url),
			   // swiftlint:enable no_optional_try
			   let title = og[.title]
			{
				let encoder = JSONEncoder()
				var preview = URLPreview(
					url: url,
					title: title,
					description: og[.description],
					imageURL: og[.image]
				)

				if let imageURL = og[.image], let url = URL(string: imageURL) {
					(preview.imageData, _) = try await URLSession.shared.data(from: url)
				}

				message.previewData = try encoder.encode(preview)
			}

			if Settings.shared.showImageURLs,
			   message.isBareImageURL,
			   let url = URL(string: message.body)
			{
				try await ImageCache.shared.save(url: url)
			}

			try message.save()
			try message.updateConversationTimestamps(conversation: conversation)

			return message
		}

		func updateConversationTimestamps(conversation: DB.Conversation) throws {
			var conversation = conversation

			if createdAt > conversation.updatedAt {
				conversation.updatedAt = createdAt
			}

			if isFromMe {
				try conversation.save()
				return
			}

			if conversation.updatedByPeerAt == nil {
				conversation.updatedByPeerAt = createdAt
			} else if let updatedByPeerAt = conversation.updatedByPeerAt, updatedByPeerAt < createdAt {
				conversation.updatedByPeerAt = createdAt
			}

			try conversation.save()
		}
	}
}

extension DB.Message: Model {
	static func == (lhs: DB.Message, rhs: DB.Message) -> Bool {
		lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}

	static func createTable(db: GRDB.Database) throws {
		try db.create(table: "message", ifNotExists: true) { t in
			t.autoIncrementedPrimaryKey("id")
			t.column("xmtpID", .text).notNull().indexed().unique()
			t.column("body", .text).notNull()
			t.column("conversationID", .integer).notNull().indexed()
			t.column("conversationTopicID", .integer).notNull().indexed()
			t.column("senderAddress", .text).notNull()
			t.column("createdAt", .date)
			t.column("isFromMe", .boolean).notNull()
			t.column("previewData", .blob)
		}
	}
}

extension DB.Message {
	static var preview: DB.Message {
		DB.Message(xmtpID: "aslkdjfalksdljkafsdjasf", body: "hello there", conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
	}

	static var previewImage: DB.Message {
		DB.Message(xmtpID: "aslkdjfalksdljkafsdjasf", body: "https://user-images.githubusercontent.com/483/219905054-3f7cc2c9-50e5-45b8-887c-82c863a01464.png", conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
	}

	static var previewGIF: DB.Message {
		DB.Message(xmtpID: "aslkdjfalksdljkafsdjasf", body: "https://heavy.com/wp-content/uploads/2014/10/mglp5o.gif", conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
	}

	static var previewWebP: DB.Message {
		DB.Message(xmtpID: "aslkdjfalksdljkafsdjasf", body: "https://media1.giphy.com/media/Fxw4gRt5Yhaw5FdAfc/giphy.webp", conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
	}

	static var previewMP4: DB.Message {
		DB.Message(xmtpID: "aslkdjfalksdljkafsdjasf", body: "https://s3.us-west-1.wasabisys.com/palmsyclub/cache/media_attachments/files/109/892/013/471/787/377/original/417fa3de9a4a1adc.mp4", conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
	}
}
