//
//  ConversationLoaderTests.swift
//  xmtp-inbox-iosTests
//
//  Created by Pat on 2/8/23.
//

import XCTest
import XMTP
import XMTPTestHelpers
@testable import xmtp_inbox_ios

final class ConversationLoaderTests: XCTestCase {
	func testGetsConversations() async throws {
		try DB.shared.prepare(passphrase: "test", mode: .test, reset: true)
		
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
}
