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

	@State private var errorViewModel = ErrorViewModel()
	@StateObject private var messageLoader: MessageLoader

	init(client: Client, conversation: DB.Conversation) {
		self.client = client
		self.conversation = conversation
		_messageLoader = StateObject(wrappedValue: MessageLoader(client: client, conversation: conversation))
	}

	// TODO(elise and pat): Paginate list of messages
	var body: some View {
		ScrollViewReader { proxy in
			ScrollView {
				VStack {
					Spacer()
					ForEach(messageLoader.messages, id: \.xmtpID) { message in
						MessageCellView(isFromMe: message.senderAddress == client.address, message: message)
							.transition(.scale)
							.id(message.xmtpID)
					}
					Spacer()
						.onChange(of: messageLoader.messages.count) { _ in
							withAnimation {
								proxy.scrollTo(messageLoader.messages.count - 1, anchor: .bottom)
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
			for topic in conversation.topics() {
				Task {
					for try await xmtpMessage in try topic.toXMTP(client: client).streamMessages() {
						let message = try DB.Message.from(xmtpMessage, conversation: conversation, topic: topic)

						await MainActor.run {
							messageLoader.messages.append(message)
						}
					}
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
			print("loading messages!")
			try await messageLoader.load()
		} catch {
			print("ERROR LOADING MESSAGSE: \(error)")
			await MainActor.run {
				self.errorViewModel.showError("Error loading messages: \(error)")
			}
		}
	}
}
