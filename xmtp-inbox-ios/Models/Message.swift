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
		var contentType: ContentTypeID
		var xmtpID: String
		var body: String
		var conversationID: Int
		var conversationTopicID: Int
		var senderAddress: String
		var createdAt: Date
		var isFromMe: Bool
		var isPending: Bool = false
		var previewData: Data?
		var fallbackContent: String?

		var attachments: [DB.MessageAttachment] = []
		var remoteAttachments: [DB.RemoteAttachment] = []

		// Cached images
		var image: Image?
		var animatedImage: Data?

		enum CodingKeys: String, CodingKey {
			case id, xmtpID, body, conversationID, conversationTopicID, senderAddress, createdAt, isFromMe, previewData, isPending, contentType, fallbackContent
		}

		init(id: Int? = nil, xmtpID: String, body: String, contentType: ContentTypeID, conversationID: Int, conversationTopicID: Int, senderAddress: String, createdAt: Date, isFromMe: Bool, fallbackContent: String? = nil) {
			self.id = id
			self.contentType = contentType
			self.xmtpID = xmtpID
			self.body = body
			self.conversationID = conversationID
			self.conversationTopicID = conversationTopicID
			self.senderAddress = senderAddress
			self.createdAt = createdAt
			self.isFromMe = isFromMe
			self.fallbackContent = fallbackContent
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

		@discardableResult static func from(_ xmtpMessage: XMTP.DecodedMessage, conversation: Conversation, topic: ConversationTopic, client: XMTP.Client) async throws -> DB.Message {
			return try await MessageCreator(client: client, conversation: conversation, topic: topic).create(xmtpMessage: xmtpMessage)
		}

		var presenter: MessagePresenter {
			MessagePresenter(message: self)
		}

		func updateConversationTimestamps(conversation: DB.Conversation) async throws {
			var conversation = conversation

			if createdAt > conversation.updatedAt {
				conversation.updatedAt = createdAt
			}

			if isFromMe {
				try await conversation.save()
				return
			}

			if conversation.updatedByPeerAt == nil {
				conversation.updatedByPeerAt = createdAt
			} else if let updatedByPeerAt = conversation.updatedByPeerAt, updatedByPeerAt < createdAt {
				conversation.updatedByPeerAt = createdAt
			}

			try await conversation.save()
		}

		mutating func save() async throws {
			do {
				try await DB.write { db in
					try insert(db, onConflict: .replace)

					guard let messageID = id else {
						throw DBError.badData("no message id after save")
					}

					for var messageAttachment in attachments {
						messageAttachment.messageID = messageID
						try messageAttachment.insert(db)
					}

					for var remoteAttachment in remoteAttachments {
						remoteAttachment.messageID = messageID
						try remoteAttachment.insert(db)
					}
				}
			} catch {
				print("Error saving \(self): \(error)")
			}
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
			t.column("isPending", .boolean).notNull().defaults(to: false)
			t.column("contentType", .blob).notNull()
			t.column("fallbackContent", .text)
		}
	}
}

extension DB.Message {
	static let attachments = hasMany(DB.MessageAttachment.self, key: "id", using: ForeignKey(["messageID"]))
	static let remoteAttachments = hasMany(DB.RemoteAttachment.self, key: "id", using: ForeignKey(["messageID"]))
}

#if DEBUG
	extension DB.Message {
		static var previewSavedImageAttachment: DB.Message {
			var message = DB.Message(xmtpID: UUID().uuidString, body: "hello there", contentType: XMTP.ContentTypeRemoteAttachment, conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
			message.attachments = [DB.MessageAttachment.previewImage]

			return message
		}

		static var previewUnsavedImageAttachment: DB.Message {
			var message = DB.Message(xmtpID: UUID().uuidString, body: "hello there", contentType: XMTP.ContentTypeRemoteAttachment, conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
			message.remoteAttachments = [DB.RemoteAttachment.previewImage]

			return message
		}

		static var previewUnknown: DB.Message {
			let unknownContentType = ContentTypeID(authorityID: "??", typeID: "??", versionMajor: 1, versionMinor: 0)
			return DB.Message(xmtpID: UUID().uuidString, body: "hello there", contentType: unknownContentType, conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true, fallbackContent: "A super cool interactive experience.")
		}

		static var preview: DB.Message {
			DB.Message(xmtpID: UUID().uuidString, body: "hello there", contentType: XMTP.ContentTypeText, conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
		}

		static var previewTxt: DB.Message {
			var message = DB.Message(xmtpID: UUID().uuidString, body: "", contentType: XMTP.ContentTypeAttachment, conversationID: 1, conversationTopicID: 1, senderAddress: "0x00000", createdAt: Date(), isFromMe: true)
			var messageAttachment = DB.MessageAttachment(mimeType: "text/plain", filename: "hello.txt")
			// swiftlint:disable force_try
			try! messageAttachment.save(data: Data("Hello world!".utf8))
			message.attachments = [messageAttachment]
			return message
		}

		static var previewImage: DB.Message {
			DB.Message(xmtpID: UUID().uuidString, body: "https://user-images.githubusercontent.com/483/219905054-3f7cc2c9-50e5-45b8-887c-82c863a01464.png", contentType: XMTP.ContentTypeText, conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
		}

		static var previewGIF: DB.Message {
			DB.Message(xmtpID: UUID().uuidString, body: "https://heavy.com/wp-content/uploads/2014/10/mglp5o.gif", contentType: XMTP.ContentTypeText, conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
		}

		static var previewWebP: DB.Message {
			DB.Message(xmtpID: UUID().uuidString, body: "https://media1.giphy.com/media/Fxw4gRt5Yhaw5FdAfc/giphy.webp", contentType: XMTP.ContentTypeText, conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
		}

		static var previewMP4: DB.Message {
			DB.Message(xmtpID: UUID().uuidString, body: "https://s3.us-west-1.wasabisys.com/palmsyclub/cache/media_attachments/files/109/892/013/471/787/377/original/417fa3de9a4a1adc.mp4", contentType: XMTP.ContentTypeText, conversationID: 1, conversationTopicID: 1, senderAddress: "0x000000000", createdAt: Date(), isFromMe: true)
		}
	}
#endif
