//
//  URLExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/15/23.
//

import Foundation

extension URL {
	init(forceString: String) {
		// swiftlint:disable force_unwrapping
		self.init(string: forceString)!
		// swiftlint:enable force_unwrapping
	}
}
