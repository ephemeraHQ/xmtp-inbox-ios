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

final class DBConversationTests: XCTestCase {
	override func setUp() async throws {
		try DB.shared.prepare(passphrase: "test", mode: .test, reset: true)
	}

	func testCanSaveAConversation() async throws {
		let date = Date()

		var conversation = DB.Conversation(topic: "m-12345678901234567890", peerAddress: "0xffffffffffffffffffffffffffffffffffffff", createdAt: date)

		try conversation.save()
		guard let id = conversation.id else {
			XCTFail("no id")
			return
		}

		guard let loadedConversation = DB.Conversation.find(id: id) else {
			XCTFail("did not load conversation")
			return
		}

		XCTAssertEqual("m-12345678901234567890", loadedConversation.topic)
		XCTAssertEqual("0xffffffffffffffffffffffffffffffffffffff", loadedConversation.peerAddress)
		XCTAssertEqual(date.formatted(), loadedConversation.createdAt.formatted())
	}
}
