//
//  DataExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/8/23.
//

import Foundation

extension Data {
	var toHex: String {
		return reduce("") { $0 + String(format: "%02x", $1) }
	}
}
