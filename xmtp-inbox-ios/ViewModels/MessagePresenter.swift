//
//  MessagePresenter.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/25/23.
//

import Foundation

// Message presenter wraps a message that gets passed down
// to swift views. By changing the message, we can let the
// views update while keeping Message a struct.
class MessagePresenter: ObservableObject {
	@Published var message: DB.Message

	init(message: DB.Message) {
		self.message = message
	}
}
