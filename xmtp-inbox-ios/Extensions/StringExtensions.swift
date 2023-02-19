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

	var isValidURL: Bool {
		do {
			let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
			if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: utf16.count)) {
				// it is a link, if the match covers the whole string
				return match.range.length == utf16.count
			} else {
				return false
			}
		} catch {
			return false
		}
	}
}
