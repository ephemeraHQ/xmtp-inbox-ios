//
//  ConversationDetailView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import AlertToast
import CryptoKit
import SwiftUI
import XMTP

struct ConversationDetailView: View {
	let client: XMTP.Client
	@State var conversation: DB.Conversation

	@State private var errorViewModel = ErrorViewModel()

	// For interactive keyboard dismiss
	@State private var offset = CGFloat()

	var body: some View {
		VStack {
			MessageListView(client: client, conversation: conversation)
				.frame(maxHeight: .infinity)
				.backgroundStyle(.blue)
			MessageComposerView(offset: $offset, onSend: sendMessage)
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
		.toast(isPresenting: $errorViewModel.isShowing) {
			AlertToast.error(errorViewModel.errorMessage)
		}
	}

	func sendMessage(text: String, attachment: Attachment? = nil) async {
		do {
			if let attachment {
				let encryptedEncodedContent = try RemoteAttachment.encodeEncrypted(content: attachment, codec: AttachmentCodec())
				if let response = try await IPFS.shared.upload(
					filename: attachment.filename,
					data: encryptedEncodedContent.payload
				) {
					let remoteAttachment = RemoteAttachment(url: "https://ipfs.io/ipfs/\(response.hash)", encryptedEncodedContent: encryptedEncodedContent)
					try await conversation.toXMTP(client: client).send(content: remoteAttachment, options: .init(contentType: ContentTypeRemoteAttachment, contentFallback: "an attachment"))
				} else {
					print("NO RESPONSE")
				}
			} else {
				// TODO(elise): Optimistic upload / undo
				try await conversation.send(text: text, client: client)
			}
		} catch {
			await MainActor.run {
				self.errorViewModel.showError("Error sending message: \(error)")
			}
		}
	}
}
