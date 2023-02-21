//
//  ConversationExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/20/23.
//

import Foundation
import XMTP

extension XMTP.Conversation {
	static func preview(client: Client) -> Conversation {
		Conversation.v2(ConversationV2(topic: "asdf", keyMaterial: Data(), context: InvitationV1.Context(), peerAddress: "0x000000", client: client))
	}
}
