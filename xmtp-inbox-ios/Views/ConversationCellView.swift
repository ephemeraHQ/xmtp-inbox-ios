//
//  ConversationListItemView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/12/23.
//

import SwiftUI
import XMTP

struct ConversationCellView: View {

    enum EnsError: Error {
        case invalidURL
    }

    var conversation: XMTP.Conversation

    var messagePreview: String

    var displayName: DisplayName

    var body: some View {
        HStack(alignment: .top) {
            EnsImageView(imageSize: 48.0, peerAddress: conversation.peerAddress)
            VStack(alignment: .leading) {
                Text(displayName.resolvedName)
                    .padding(.horizontal, 4.0)
                    .padding(.bottom, 1.0)
                    .lineLimit(1)
                    .font(.Body1B)
                if messagePreview.isEmpty {
                    Text("no-message-preview")
                        .padding(.horizontal, 4.0)
                        .lineLimit(1)
                        .font(.Body2)
                        .foregroundColor(.textScondary)
                        .italic()
                } else {
                    Text(messagePreview)
                        .padding(.horizontal, 4.0)
                        .lineLimit(1)
                        .font(.Body2)
                        .foregroundColor(.textScondary)
                }
            }
        }
    }
}
