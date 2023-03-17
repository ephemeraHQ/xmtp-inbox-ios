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
	var db: DB!

	override func setUp() async throws {
		fixtures = await fixtures()
		db = try await DB.prepareTest()
	}

	func testCanSaveAConversation() async throws {
		let date = Date()

		var conversation = DB.Conversation(peerAddress: "0xffffffffffffffffffffffffffffffffffffff", createdAt: date)

		try conversation.save(db: db)
		guard let id = conversation.id else {
			XCTFail("no id")
			return
		}

		guard let loadedConversation = DB.Conversation.using(db: db).find(id: id) else {
			XCTFail("did not load conversation")
			return
		}

		XCTAssertEqual("0xffffffffffffffffffffffffffffffffffffff", loadedConversation.peerAddress)
		XCTAssertEqual(date.formatted(), loadedConversation.createdAt.formatted())
	}
}
