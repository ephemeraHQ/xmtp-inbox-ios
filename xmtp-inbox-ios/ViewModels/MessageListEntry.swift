//
//  MessageListEntry.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/17/23.
//

import Foundation

enum MessageListEntry {
	case message(DB.Message), timestamp(Date), typing
}
