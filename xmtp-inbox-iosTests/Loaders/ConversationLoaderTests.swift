//
//  ConversationLoaderTests.swift
//  xmtp-inbox-iosTests
//
//  Created by Pat on 2/8/23.
//

import Foundation
import XCTest
import XMTP
@testable import xmtp_inbox_ios

final class ConversationLoaderTests: XCTestCase {
	override func setUp() async throws {
		try DB.shared.prepare(passphrase: "test", mode: .test, reset: true)
	}
	
	func testGetsConversations() async throws {
		let client = XMTP.Client.
	}
}
