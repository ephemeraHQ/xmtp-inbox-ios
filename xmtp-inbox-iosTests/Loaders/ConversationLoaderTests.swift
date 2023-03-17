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
	var fixtures: XMTPTestHelpers.Fixtures!
	var db: DB!

	override func setUp() async throws {
		fixtures = await fixtures()
		db = DB.prepareTest()
	}

	func testENSRefreshesFirstTime() async throws {
		AppGroup.defaults.removeObject(forKey: "ensRefreshedAt")
		let loader = ConversationLoader(client: fixtures.aliceClient, db: db)
		let ens = TestENS()

		let expectation = expectation(description: "looked up ENS")
		ens.spy = { _ in expectation.fulfill() }

		loader.ensService = ens

		try await loader.load()

		await waitForExpectations(timeout: 3)
	}

	func testENSSkipsRefreshIfWithin1Hour() async throws {
		AppGroup.defaults.removeObject(forKey: "ensRefreshedAt")
		let loader = ConversationLoader(client: fixtures.aliceClient, db: db)
		let ens = TestENS()

		let expectation = expectation(description: "looked up ENS")
		ens.spy = { _ in expectation.fulfill() }

		loader.ensService = ens

		try await loader.load()

		AppGroup.defaults.set(Date().addingTimeInterval(-(60 * 2)), forKey: "ensRefreshedAt") // we checked two minutes ago

		let loader2 = ConversationLoader(client: fixtures.aliceClient, db: db)
		loader2.ensService = ens
		try await loader2.load()

		await waitForExpectations(timeout: 3)
	}

	func testGetsConversations() async throws {
		let db = DB.prepareTest()
		try db.clear()
		try db.createTables()
		let fixtures = await fixtures()
		let loader = ConversationLoader(client: fixtures.aliceClient, db: db)

		var conversations = DB.Conversation.using(db: db).list()
		print("CONVERSATIONS: \(conversations)")
		XCTAssert(conversations.isEmpty, "had conversations for some reason??")

		let conversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)
		let clientConversations = try await fixtures.aliceClient.conversations.list()

		XCTAssertEqual(1, clientConversations.count)

		try await loader.load()
		conversations = DB.Conversation.using(db: db).list()

		XCTAssertEqual(1, conversations.count)

		let loadedConversation = conversations[0]
		let topics = loadedConversation.topics(db: db)

		XCTAssertEqual([conversation.topic], topics.map(\.topic))
	}

	func testCreatesOneConversationForMultipleTopicsWithSamePeerAddress() async throws {
		let aliceConversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)
		let bobConversation = try await fixtures.bobClient.conversations.newConversation(with: fixtures.aliceClient.address)

		XCTAssertNotEqual(aliceConversation.topic, bobConversation.topic)

		_ = try await aliceConversation.send(text: "hi from alice")
		_ = try await bobConversation.send(text: "hi from bob")

		let loader = ConversationLoader(client: fixtures.aliceClient, db: db)
		try await loader.load()

		let xmtpConversations = try await fixtures.aliceClient.conversations.list()
		XCTAssertEqual(2, xmtpConversations.count)

		let conversations = DB.Conversation.using(db: db).list()
		XCTAssertEqual(1, conversations.count)

		print("\(conversations)")

		XCTAssertEqual(1, conversations.count)
		let conversation = conversations[0]
		XCTAssertEqual(conversation.peerAddress, fixtures.bobClient.address)

		let topics = conversation.topics(db: db)
		XCTAssertEqual(2, topics.count)
	}
}
