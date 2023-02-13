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
	var environmentOverride: String? {
		didSet {
			if environmentOverride == "dev" {
				AppGroup.defaults.set("dev", forKey: key)
				environment = .dev
			} else {
				AppGroup.defaults.set("production", forKey: key)
				environment = .production
			}

			Auth.signOut()
		}
	}

	@Published var environment: XMTPEnvironment

	static let shared = XMTPEnvironmentManager()

	private init() {
		#if DEBUG
			environment = .dev
		#else
			environment = .production
		#endif

		environmentOverride = AppGroup.defaults.string(forKey: key)
	}
}
