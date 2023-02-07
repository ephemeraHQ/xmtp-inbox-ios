//
//  ConversationListItemView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/12/23.
//

import SwiftUI
import XMTP

struct ConversationCellView: View {
	var conversation: DB.Conversation

	var body: some View {
		HStack(alignment: .top) {
			EnsImageView(imageSize: 48.0, peerAddress: conversation.peerAddress)
			VStack(alignment: .leading) {
				HStack {
					Text(conversation.title)
						.padding(.horizontal, 4.0)
						.padding(.bottom, 1.0)
						.lineLimit(1)
						.font(.Body1B)
					if let lastMessage = conversation.lastMessage {
						Text(lastMessage.createdAt.timeAgo)
							.frame(maxWidth: .infinity, alignment: .trailing)
							.lineLimit(1)
							.font(.BodyXS)
							.foregroundColor(.textScondary)
							.padding(.horizontal, 4.0)
							.padding(.bottom, 1.0)
					}
				}
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

	var messagePreview: String {
		return conversation.lastMessage?.body ?? ""
	}
}
