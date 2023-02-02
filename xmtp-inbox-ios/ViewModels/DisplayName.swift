//
//  DisplayName.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/25/23.
//

import Foundation

struct DisplayName {
	var ensName: String?
	var address: String

	var resolvedName: String {
		ensName ?? address.truncatedAddress()
	}
}
