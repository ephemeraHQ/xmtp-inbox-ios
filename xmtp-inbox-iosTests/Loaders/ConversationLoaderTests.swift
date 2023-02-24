//
//  ConversationLoaderTests.swift
//  xmtp-inbox-iosTests
//
//  Created by Pat on 2/8/23.
//

import GRDB
import XCTest
import XMTP
import XMTPTestHelpers
@testable import xmtp_inbox_ios

final class ConversationLoaderTests: XCTestCase {
	var fixtures: XMTPTestHelpers.Fixtures!

	override func setUp() async throws {
		self.fixtures = await fixtures()
	}

	func testGetsConversations() async throws {
		try DB.prepareTest(client: fixtures.aliceClient)

		let loader = ConversationLoader(client: fixtures.aliceClient)

		var conversations = DB.Conversation.list()
		XCTAssert(conversations.isEmpty, "had conversations for some reason??")

		let conversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)
		let clientConversations = try await fixtures.aliceClient.conversations.list()

		XCTAssertEqual(1, clientConversations.count)

		try await loader.load()
		conversations = DB.Conversation.list()

		XCTAssertEqual([conversation.topic], conversations.flatMap { $0.topics().map(\.topic) })
	}

	func testCreatesOneConversationForMultipleTopicsWithSamePeerAddress() async throws {
		try DB.prepareTest(client: fixtures.aliceClient)

		let aliceConversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)
		let bobConversation = try await fixtures.bobClient.conversations.newConversation(with: fixtures.aliceClient.address)

		XCTAssertNotEqual(aliceConversation.topic, bobConversation.topic)

		_ = try await aliceConversation.send(text: "hi from alice")
		_ = try await bobConversation.send(text: "hi from bob")

		let loader = ConversationLoader(client: fixtures.aliceClient)
		try await loader.load()

		let xmtpConversations = try await fixtures.aliceClient.conversations.list()
		XCTAssertEqual(2, xmtpConversations.count)

		let conversations = DB.Conversation.list()
		XCTAssertEqual(1, conversations.count)

		print("\(conversations)")

		XCTAssertEqual(1, conversations.count)
		let conversation = conversations[0]
		XCTAssertEqual(conversation.peerAddress, fixtures.bobClient.address)
		XCTAssertEqual(2, conversation.topics().count)
	}
}
