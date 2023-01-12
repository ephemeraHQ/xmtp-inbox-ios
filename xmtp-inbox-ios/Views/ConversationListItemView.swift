//
//  ConversationListItemView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/12/23.
//

import SwiftUI
import XMTP

struct ConversationListItemView: View {

    var conversation: XMTP.Conversation

    var body: some View {
        Text(conversation.peerAddress)
    }
}
