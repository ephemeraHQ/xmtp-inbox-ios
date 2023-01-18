//
//  Constants.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/16/23.
//

import Foundation
import XMTP

struct Constants {
    static let xmtpEnv: XMTPEnvironment = .dev
    static let infuraUrl = URL(string: ProcessInfo.processInfo.environment["INFURA_MAINNET_URL"] ?? "")
}
