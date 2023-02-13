//
//  ConversationLoaderTests.swift
//  xmtp-inbox-iosTests
//
//  Created by Pat on 2/8/23.
//

import GRDB
import XCTest
import XMTP
@testable import xmtp_inbox_ios
import XMTPTestHelpers

final class ConversationLoaderTests: XCTestCase {
	override func setUp() async throws {
		try DB.shared.prepare(passphrase: "test", mode: .test, reset: true)
	}

	func testGetsConversations() async throws {
		let fixtures = await fixtures()
		let loader = ConversationLoader(client: fixtures.aliceClient)

		var conversations = await loader.conversations
		XCTAssert(conversations.isEmpty, "had conversations for some reason??")

		let conversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)
		let clientConversations = try await fixtures.aliceClient.conversations.list()

		XCTAssertEqual(1, clientConversations.count)

		try await loader.load()
		conversations = await loader.conversations

		XCTAssertEqual([conversation.topic], conversations.flatMap { $0.topics().map(\.topic) })
	}

	func testGetsMostRecentMessage() async throws {
		let fixtures = await fixtures()
		let loader = ConversationLoader(client: fixtures.aliceClient)

		let conversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)
		try await conversation.send(text: "1")

		try await loader.load()
		var conversations = await loader.conversations
		let loadedConversation = conversations[0]

		XCTAssertEqual("1", loadedConversation.lastMessage?.body)

		let thePast = Date().addingTimeInterval(-1000)
		try await DB.shared.queue.write { db in
			try db.execute(sql: "UPDATE message SET createdAt = ?", arguments: [thePast])
		}

		try await conversation.send(text: "2")

		try await loader.load()
		conversations = await loader.conversations

		let messages = try await DB.shared.queue.read { db in
			try DB.Message.order(Column("createdAt").desc).fetchAll(db)
		}

		print("msesagse \(messages)")

		XCTAssertEqual("2", conversations[0].lastMessage?.body)

		try await loader.load()
		try await loader.load()
		try await loader.load()

		conversations = await loader.conversations
		XCTAssertEqual(loadedConversation.id, conversations[0].id)
		XCTAssertEqual("2", conversations[0].lastMessage?.body)
	}

	func testCreatesOneConversationForMultipleTopicsWithSamePeerAddress() async throws {
		Auth.signOut()
		try DB.shared.prepare(passphrase: "test", mode: .test, reset: true)
		let fixtures = await fixtures()

		let aliceConversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)
		let bobConversation = try await fixtures.bobClient.conversations.newConversation(with: fixtures.aliceClient.address)

		XCTAssertNotEqual(aliceConversation.topic, bobConversation.topic)

		print("ALICE CONVERSATION TOPIC \(aliceConversation.topic)")
		print("BOB CONVERSATION TOPIC \(bobConversation.topic)")

		try await aliceConversation.send(text: "hi from alice")
		try await bobConversation.send(text: "hi from bob")

		let loader = ConversationLoader(client: fixtures.aliceClient)
		try await loader.load()

		let xmtpConversations = try await fixtures.aliceClient.conversations.list()
		XCTAssertEqual(2, xmtpConversations.count)

		let conversations = await loader.conversations
		XCTAssertEqual(1, conversations.count)

		let conversation = conversations[0]
		XCTAssertEqual(1, conversations.count)
		print("topics \(conversations[0].topics())")
		XCTAssertEqual(conversation.peerAddress, fixtures.bobClient.address)
		XCTAssertEqual(2, conversation.topics().count)
	}
}
