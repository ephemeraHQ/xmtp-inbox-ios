//
//  xmtp_inbox_iosUITests.swift
//  xmtp-inbox-iosUITests
//
//  Created by Elise Alix on 12/20/22.
//

import XCTest

final class xmtp_inbox_iosUITests: XCTestCase {
	func testAppALaunches() throws {
		let app = XCUIApplication()
		app.launch()

		let connectButton = app.buttons["Connect your wallet"]
		connectButton.waitForExistence(timeout: 10)

		XCTAssert(connectButton.exists)
	}
}
