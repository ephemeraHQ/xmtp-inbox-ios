//
//  Constants.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/16/23.
//

import Foundation
import XMTP

struct Constants {
	static var xmtpEnv: XMTPEnvironment {
		XMTPEnvironmentManager.shared.environment
	}

	static var xmtpPush: String {
		if XMTPEnvironmentManager.shared.environment == .production {
			return "https://notifications.production.xmtp.network"
		} else {
			return "https://notifications.dev.xmtp.network"
		}
	}

	private static let infuraKey = Bundle.main.infoDictionary?["INFURA_KEY"] as? String ?? ""
	static let infuraUrl = URL(string: "https://mainnet.infura.io/v3/\(infuraKey)")
	static let hasInfuraKey = !infuraKey.isEmpty

	static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
	static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
}
