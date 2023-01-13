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

    @State private var status: LoadingStatus = .loading

    var body: some View {
        ZStack {
            switch status {
            case .loading, .empty:
                Text(conversation.peerAddress)
            case let .error(error):
                Text(conversation.peerAddress).task {
                    print(error)
                }
            case .success:
                Text(conversation.peerAddress)
            }
        }
        .task {
            await loadDisplayName()
        }
        .task {
            await loadAvatar()
        }
    }

    func loadDisplayName() async {
        // TODO(elise): Load ENS name
    }

    func loadAvatar() async {
        // TODO(elise): Load ENS image or fallback
    }
}
