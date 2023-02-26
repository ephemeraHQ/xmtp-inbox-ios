//
//  MessagePresenter.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/25/23.
//

import Foundation

class MessagePresenter: ObservableObject {
	@Published var message: DB.Message

	init(message: DB.Message) {
		self.message = message
	}
}
