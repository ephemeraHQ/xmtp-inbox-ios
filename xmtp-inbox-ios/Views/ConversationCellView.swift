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

	var isUnread: Bool {
		guard let viewedAt = conversation.viewedAt,
		      let updatedByPeerAt = conversation.updatedByPeerAt
		else {
			return false
		}

		return viewedAt < updatedByPeerAt
	}

	var body: some View {
		HStack(alignment: .center, spacing: 8) {
			Circle()
				.fill(isUnread ? Color.blue : Color.clear)
				.frame(width: 8, height: 8)
			HStack(alignment: .top) {
				AvatarView(imageSize: 48.0, peerAddress: conversation.peerAddress)
				VStack(alignment: .leading) {
					HStack {
						Text(conversation.title)
							.padding(.horizontal, 4.0)
							.padding(.bottom, 1.0)
							.lineLimit(1)
							.font(.Body1B)
						UpdatingRelativeTimestamp(conversation.lastMessage?.createdAt ?? conversation.updatedAt)
							.frame(maxWidth: .infinity, alignment: .trailing)
							.lineLimit(1)
							.font(.BodyXS)
							.foregroundColor(.textScondary)
							.padding(.horizontal, 4.0)
							.padding(.bottom, 1.0)
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
	}

	var messagePreview: String {
		return conversation.lastMessage?.body ?? ""
	}
}
