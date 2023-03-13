//
//  DBConversationTests.swift
//  xmtp-inbox-iosTests
//
//  Created by Pat Nakajima on 2/2/23.
//

import Foundation
import XCTest
import XMTP
@testable import xmtp_inbox_ios
import XMTPTestHelpers

final class DBConversationTests: XCTestCase {
	var fixtures: XMTPTestHelpers.Fixtures!

	override func setUp() async throws {
		fixtures = await fixtures()
		try await DB.prepareTest(client: fixtures.aliceClient)
	}

	func testCanSaveAConversation() async throws {
		let date = Date()

		var conversation = DB.Conversation(peerAddress: "0xffffffffffffffffffffffffffffffffffffff", createdAt: date)

		try await conversation.save()
		guard let id = conversation.id else {
			XCTFail("no id")
			return
		}

		guard let loadedConversation = await DB.Conversation.find(id: id) else {
			XCTFail("did not load conversation")
			return
		}

		XCTAssertEqual("0xffffffffffffffffffffffffffffffffffffff", loadedConversation.peerAddress)
		XCTAssertEqual(date.formatted(), loadedConversation.createdAt.formatted())
	}
}
