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

    let conversation: Conversation

    @State private var messages: [DecodedMessage] = []

    @State private var errorViewModel = ErrorViewModel()

        // TODO(elise): Paginate list of messages and migrate fetch into MessageListView
        // to match ConversationListView.
    /** Reverses the message list to render from bottom to top. */
    var body: some View {
//        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    Spacer()
                    ForEach(Array(messages.sorted(by: { $0.sent > $1.sent }).enumerated()), id: \.0) { i, message in
                        MessageCellView(isFromMe: message.senderAddress == client.address, message: message)
                            .transition(.scale)
                            .id(i)
                            .scaleEffect(x: 1, y: -1, anchor: .center)
                    }
                    Spacer()
                }
//            }
            }
            .scaleEffect(x: 1, y: -1, anchor: .center)
            .padding(.horizontal)
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
            self.errorViewModel.showError("Error streaming messages: \(error)")
        }
    }

    func loadMessages() async {
        do {
            let messages = try await conversation.messages()
            await MainActor.run {
                self.messages = messages
            }
        } catch {
            self.errorViewModel.showError("Error loading detail messages: \(error)")
        }
    }
}
