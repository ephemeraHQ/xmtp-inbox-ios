//
//  ConversationPresenter.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 3/28/23.
//

import Foundation

class ConversationPresenter: ObservableObject {
	@Published var conversation: DB.Conversation

	init(conversation: DB.Conversation) {
		self.conversation = conversation
	}
}
