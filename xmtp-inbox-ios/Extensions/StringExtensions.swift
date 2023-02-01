//
//  StringExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/16/23.
//

import Foundation

extension String {
	func truncatedAddress() -> String {
		if count > 6 {
			let start = index(startIndex, offsetBy: 6)
			let end = index(endIndex, offsetBy: -5)
			return replacingCharacters(in: start ... end, with: "...")
		}
		return self
	}
}
