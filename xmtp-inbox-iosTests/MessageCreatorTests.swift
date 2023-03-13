//
//  MessageCreatorTests.swift
//  xmtp-inbox-iosTests
//
//  Created by Pat on 2/25/23.
//

import Foundation
import XCTest
import XMTP
@testable import xmtp_inbox_ios
import XMTPTestHelpers

class MessageCreatorTests: XCTestCase {
	var fixtures: XMTPTestHelpers.Fixtures!

	override func setUp() async throws {
		Client.register(codec: AttachmentCodec())
		Client.register(codec: RemoteAttachmentCodec())
		fixtures = await fixtures()
		try await DB.prepareTest(client: fixtures.aliceClient)
	}

	func testCreatesXMTPMessage() async throws {
		let conversation = try! await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)
		_ = try! await conversation.send(text: "hello world")
		let xmtpMessage = try! await conversation.messages()[0]

		let dbConversation = try! await DB.Conversation.from(conversation)
		let dbTopic =  (await dbConversation.topics())[0]

		let creator = MessageCreator(client: fixtures.aliceClient, conversation: dbConversation, topic: dbTopic)

		let message = try await creator.create(xmtpMessage: xmtpMessage)

		XCTAssertEqual(message.xmtpID, xmtpMessage.id)
		XCTAssertEqual(message.body, "hello world")
		XCTAssertEqual(message.createdAt, xmtpMessage.sent)
		XCTAssert(!message.isPending)
	}

	func testCreatesXMTPMessageWithRemoteAttachment() async throws {
		let conversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)
		let enecryptedEncodedContent = try RemoteAttachment.encodeEncrypted(content: Attachment(filename: "hi.txt", mimeType: "text/plain", data: Data("hi".utf8)), codec: AttachmentCodec())
		var remoteAttachmentContent = try RemoteAttachment(url: "https://example.com", encryptedEncodedContent: enecryptedEncodedContent)
		remoteAttachmentContent.filename = "hi.txt"
		remoteAttachmentContent.contentLength = 5

		_ = try await conversation.send(content: remoteAttachmentContent, options: .init(contentType: ContentTypeRemoteAttachment, contentFallback: "hey"))
		let xmtpMessage = try await conversation.messages()[0]

		let dbConversation = try await DB.Conversation.from(conversation)
		let dbTopic = (await dbConversation.topics())[0]

		let creator = MessageCreator(client: fixtures.aliceClient, conversation: dbConversation, topic: dbTopic)

		let message = try await creator.create(xmtpMessage: xmtpMessage)

		XCTAssertEqual(1, message.remoteAttachments.count)
		let remoteAttachment = message.remoteAttachments[0]
		XCTAssertEqual(remoteAttachment.url, "https://example.com")
		XCTAssertEqual(remoteAttachment.salt, remoteAttachmentContent.salt)
		XCTAssertEqual(remoteAttachment.nonce, remoteAttachmentContent.nonce)
		XCTAssertEqual(remoteAttachment.secret, remoteAttachmentContent.secret)

		XCTAssertEqual(remoteAttachment.url, "https://example.com")
		XCTAssertEqual(remoteAttachment.contentLength, 5)
		XCTAssertEqual(remoteAttachment.filename, "hi.txt")

		XCTAssertEqual(message.xmtpID, xmtpMessage.id)
		XCTAssertEqual(message.fallbackContent, "hey")
		XCTAssertEqual(message.createdAt, xmtpMessage.sent)
		XCTAssert(!message.isPending)
	}

	func testSendsXMTPMessage() async throws {
		let conversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)

		let dbConversation = try await DB.Conversation.from(conversation)
		let dbTopic = (await dbConversation.topics())[0]

		let creator = MessageCreator(client: fixtures.aliceClient, conversation: dbConversation, topic: dbTopic)

		let message = try await creator.send(text: "Hello again", attachment: nil)

		let xmtpMessages = try await conversation.messages()
		let xmtpMessage = xmtpMessages[0]

		XCTAssertEqual(message.xmtpID, xmtpMessage.id)
		XCTAssertEqual(message.body, "Hello again")
		XCTAssertEqual(message.createdAt.timeAgo, xmtpMessage.sent.timeAgo)
	}

	func testSendsXMTPMessageWithRemoteAttachment() async throws {
		let iconData = try Data(contentsOf: DB.MessageAttachment.previewImage.location)

		let conversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)

		let dbConversation = try await DB.Conversation.from(conversation)
		let dbTopic = (await dbConversation.topics())[0]

		var creator = MessageCreator(client: fixtures.aliceClient, conversation: dbConversation, topic: dbTopic)
		creator.uploader = TestUploader()
		let attachment = Attachment(filename: "icon.png", mimeType: "image/png", data: iconData)

		let message = try await creator.send(text: "Hello again", attachment: attachment)

		let xmtpMessages = try await conversation.messages()
		let xmtpMessage = xmtpMessages[0]

		// Makes a message attachment locally
		XCTAssertEqual(1, message.attachments.count)
		XCTAssertEqual("icon.png", message.attachments[0].filename)
		XCTAssertEqual("image/png", message.attachments[0].mimeType)
		XCTAssertEqual(iconData, try Data(contentsOf: message.attachments[0].location))

		// Sends a remote attachment
		let sentRemoteAttachment: RemoteAttachment = try xmtpMessage.content()
		XCTAssertEqual("icon.png", sentRemoteAttachment.filename)

		XCTAssertEqual(message.xmtpID, xmtpMessage.id)
		XCTAssertEqual(message.body, "Hello again")
		XCTAssertEqual(message.createdAt.timeAgo, xmtpMessage.sent.timeAgo)
	}
}
