//
//  DateExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 2/2/23.
//

import Foundation

extension Date {
	func timeAgo() -> String {
		let formatter = RelativeDateTimeFormatter()
		formatter.unitsStyle = .short
		return formatter.localizedString(for: self, relativeTo: Date())
	}
}
