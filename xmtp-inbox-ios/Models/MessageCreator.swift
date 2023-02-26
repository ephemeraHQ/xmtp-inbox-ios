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
	var client: Client
	var conversation: DB.Conversation
	var topic: DB.ConversationTopic

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
				let uploadedURL = try await S3Uploader(data: encryptedEncoded.payload).upload()
				var remoteAttachment = try RemoteAttachment(url: uploadedURL, encryptedEncodedContent: encryptedEncoded)
				remoteAttachment.filename = attachment.filename
				remoteAttachment.contentLength = attachment.data.count

				print("SENDING WITH ATTACHMENT \(remoteAttachment)")
				contentType = ContentTypeRemoteAttachment
				messageID = try await topic.toXMTP(client: client).send(content: remoteAttachment, options: .init(contentType: ContentTypeRemoteAttachment, contentFallback: text))
				print("GOT MESSAGE ID BACK \(messageID)")
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
		if let existing = DB.Message.find(Column("xmtpID") == xmtpMessage.id) {
			try existing.updateConversationTimestamps(conversation: conversation)
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

		try message.save()
		try message.updateConversationTimestamps(conversation: conversation)
	}

	func handleRemoteAttachments(message: inout DB.Message, xmtpMessage: XMTP.DecodedMessage) {
		do {
			let remoteAttachmentContent: RemoteAttachment = try xmtpMessage.content()

			var remoteAttachment = DB.RemoteAttachment(
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
