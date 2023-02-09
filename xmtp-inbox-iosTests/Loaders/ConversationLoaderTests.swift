//
//  ConversationLoaderTests.swift
//  xmtp-inbox-iosTests
//
//  Created by Pat on 2/8/23.
//

import XCTest
import XMTP
import XMTPTestHelpers
import GRDB
@testable import xmtp_inbox_ios

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
		
		XCTAssertEqual([conversation.topic], conversations.map(\.topic))
	}

	func testGetsMostRecentMessage() async throws {
		let fixtures = await fixtures()
		let loader = ConversationLoader(client: fixtures.aliceClient)

		let conversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)
		try await conversation.send(text: "1")

		try await loader.load()
		var conversations = await loader.conversations

		XCTAssertEqual("1", conversations[0].lastMessage?.body)

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

	}
}
