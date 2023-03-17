//
//  MessageCreator.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/24/23.
//

import GRDB
import OpenGraph
import XMTP

struct MessageCreator {
	var db: DB
	var client: Client
	var conversation: DB.Conversation
	var topic: DB.ConversationTopic
	var uploader: Uploader = Web3Storage()

	init(db: DB, client: Client, conversation: DB.Conversation, topic: DB.ConversationTopic, uploader: Uploader = Web3Storage()) {
		self.db = db
		self.client = client
		self.conversation = conversation
		self.topic = topic
		self.uploader = uploader
	}

	func send(text: String, attachment: XMTP.Attachment?) async throws -> DB.Message {
		guard let topicID = topic.id else {
			throw DB.Conversation.ConversationError.conversionError("no conversation/topic ID")
		}

		let date = Date()
		var messageID: String
		var contentType: ContentTypeID

		if let attachment {
			do {
				let encryptedEncoded = try RemoteAttachment.encodeEncrypted(content: attachment, codec: AttachmentCodec())
				let uploadedURL = try await uploader.upload(data: encryptedEncoded.payload)
				var remoteAttachment = try RemoteAttachment(url: uploadedURL, encryptedEncodedContent: encryptedEncoded)
				remoteAttachment.filename = attachment.filename
				remoteAttachment.contentLength = attachment.data.count

				contentType = ContentTypeRemoteAttachment
				messageID = try await topic.toXMTP(client: client).send(content: remoteAttachment, options: .init(contentType: ContentTypeRemoteAttachment, contentFallback: text))
			} catch {
				print("ERROR SENDING REMOTE ATTACHMENT \(error)")
				throw error
			}
		} else {
			contentType = ContentTypeText
			messageID = try await topic.toXMTP(client: client).send(text: text)
		}

		var message = DB.Message(
			xmtpID: messageID,
			body: text,
			contentType: contentType,
			conversationID: topic.conversationID,
			conversationTopicID: topicID,
			senderAddress: topic.peerAddress,
			createdAt: date,
			isFromMe: true
		)

		if let attachment {
			var messageAttachment = DB.MessageAttachment(mimeType: attachment.mimeType, filename: attachment.filename, uuid: UUID())
			try messageAttachment.save(data: attachment.data)

			message.attachments = [messageAttachment]
		}

		try await finish(message: &message)

		return message
	}

	func create(xmtpMessage: XMTP.DecodedMessage) async throws -> DB.Message {
		if let existing = DB.Message.using(db: db).find(Column("xmtpID") == xmtpMessage.id) {
			try await existing.updateConversationTimestamps(conversation: conversation, db: db)
			return existing
		}

		guard let conversationID = conversation.id, let topicID = topic.id else {
			throw DB.Conversation.ConversationError.conversionError("no conversation/topic ID")
		}

		if xmtpMessage.id == "" {
			throw DB.DBError.badData("Missing XMTP ID")
		}

		var message = DB.Message(
			xmtpID: xmtpMessage.id,
			body: (try? xmtpMessage.content()) ?? "",
			contentType: xmtpMessage.encodedContent.type,
			conversationID: conversationID,
			conversationTopicID: topicID,
			senderAddress: xmtpMessage.senderAddress,
			createdAt: xmtpMessage.sent,
			isFromMe: client.address == xmtpMessage.senderAddress,
			fallbackContent: xmtpMessage.fallbackContent
		)

		handleRemoteAttachments(message: &message, xmtpMessage: xmtpMessage)

		try await finish(message: &message)

		return message
	}

	func finish(message: inout DB.Message) async throws {
		await loadPreview(message: &message)

		try await message.save(db: db)
		try await message.updateConversationTimestamps(conversation: conversation, db: db)
	}

	func handleRemoteAttachments(message: inout DB.Message, xmtpMessage: XMTP.DecodedMessage) {
		if xmtpMessage.encodedContent.type != ContentTypeRemoteAttachment {
			return
		}

		do {
			let remoteAttachmentContent: RemoteAttachment = try xmtpMessage.content()

			let remoteAttachment = DB.RemoteAttachment(
				url: remoteAttachmentContent.url,
				salt: remoteAttachmentContent.salt,
				nonce: remoteAttachmentContent.nonce,
				secret: remoteAttachmentContent.secret,
				contentDigest: remoteAttachmentContent.contentDigest,
				filename: remoteAttachmentContent.filename,
				contentLength: remoteAttachmentContent.contentLength
			)

			message.remoteAttachments = [remoteAttachment]
		} catch {
			print("Error handling remote attachment: \(error)")
		}
	}

	func loadPreview(message: inout DB.Message) async {
		do {
			if Settings.shared.showLinkPreviews,
			   message.body.isValidURL,
			   let url = URL(string: message.body),
			   let og = try? await OpenGraph.fetch(url: url),
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
		} catch {
			print("Error loading link preview: \(error)")
		}
	}
}
