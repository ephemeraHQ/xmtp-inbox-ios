//
//  ConversationKey.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/18/23.
//

import Foundation

func buildConversationKey(peerAddress: String, conversationId: String) -> String {
    return "\(peerAddress)/\(conversationId)"
}
