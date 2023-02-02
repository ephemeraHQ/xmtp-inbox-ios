//
//  MessageListView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/5/22.
//

import SwiftUI
import XMTP

struct MessageListView: View {
	let client: Client

	let conversation: DB.Conversation

	@State private var messages: [DecodedMessage] = []

	@State private var errorViewModel = ErrorViewModel()

	// TODO(elise): Paginate list of messages
	var body: some View {
		ScrollViewReader { proxy in
			ScrollView {
				VStack {
					Spacer()
					ForEach(Array(messages.sorted(by: { $0.sent > $1.sent }).enumerated()), id: \.0) { i, message in
						MessageCellView(isFromMe: message.senderAddress == client.address, message: message)
							.transition(.scale)
							.id(i)
					}
					Spacer()
						.onChange(of: messages.count) { _ in
							withAnimation {
								proxy.scrollTo(messages.count - 1, anchor: .bottom)
							}
						}
				}
			}
			.padding(.horizontal)
		}
		.task {
			await loadMessages()
		}
		.task {
			await streamMessages()
		}
	}

	func streamMessages() async {
		do {
			for try await message in conversation.streamMessages() {
				await MainActor.run {
					messages.append(message)
				}
			}
		} catch {
			await MainActor.run {
				self.errorViewModel.showError("Error streaming messages: \(error)")
			}
		}
	}

	func loadMessages() async {
		do {
			let messages = try await conversation.messages()
			await MainActor.run {
				self.messages = messages
			}
		} catch {
			await MainActor.run {
				self.errorViewModel.showError("Error streaming messages: \(error)")
			}
		}
	}
}
