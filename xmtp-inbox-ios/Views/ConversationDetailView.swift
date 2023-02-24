//
//  ConversationDetailView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import SwiftUI
import XMTP

struct ConversationDetailView: View {
	let client: XMTP.Client
	@State var conversation: DB.Conversation

	// For interactive keyboard dismiss
	@State private var offset = CGFloat()

	var body: some View {
		VStack {
			MessageListView(client: client, conversation: conversation)
				.frame(maxHeight: .infinity)
				.backgroundStyle(.blue)
			MessageComposerView(offset: $offset, onSend: sendMessage(text:))
				.padding(.horizontal)
				.padding(.bottom)
		}
		.padding(.bottom, -offset) // For interactive keyboard dismiss
		.background(.clear)
		.navigationTitle(conversation.title)
		.navigationBarTitleDisplayMode(.inline)
		.toolbarBackground(.visible, for: .navigationBar)
		.onAppear {
			do {
				try conversation.markViewed()
			} catch {
				print("Error marking conversation as viewed: \(error)")
			}
		}
	}

	func sendMessage(text: String) async {
		do {
			// TODO(elise): Optimistic upload / undo
			try await conversation.send(text: text, client: client)
		} catch {
			await MainActor.run {
				Flash.add(.error("Error sending message: \(error)"))
			}
		}
	}
}
