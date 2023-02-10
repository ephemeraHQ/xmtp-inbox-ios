//
//  AppGroup.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/9/23.
//

import Foundation
import KeychainAccess

struct AppGroup {
	static let identifier = "group.com.xmtplabs.inbox.ios"

	static var containerURL: URL {
		guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
			fatalError("Could not load container URL")
		}

		return containerURL
	}

	static var defaults: UserDefaults {
		guard let defaults = UserDefaults(suiteName: identifier) else {
			fatalError("Could not load defaults")
		}

		return defaults
	}

	static var keychain: Keychain {
		return Keychain(service: "com.xmtplabs.inbox.ios", accessGroup: "FY4NZR34Z3.com.xmtplabs.inbox.ios")
			.synchronizable(true)
			.accessibility(.afterFirstUnlock)
	}
}
