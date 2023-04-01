//
//  XMTPEnvironmentManager.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/13/23.
//

import Foundation
import XMTP

class XMTPEnvironmentManager: ObservableObject {
	let key = "xmtpEnvironment"

	@Published var environment: XMTPEnvironment

	static let shared = XMTPEnvironmentManager()

	private init() {
		#if DEBUG
			environment = .local
		#else
			environment = .production
		#endif
	}
}
