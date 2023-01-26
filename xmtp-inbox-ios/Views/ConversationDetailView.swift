//
//  ConversationDetailView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import SwiftUI
import XMTP

struct ConversationDetailView: View {

    var client: XMTP.Client

    var displayName: DisplayName

    var conversation: XMTP.Conversation

    @State private var messages: [DecodedMessage] = []

    var body: some View {
        ZStack {
            Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
            VStack {
                // TODO(elise): Paginate list of messages
                MessageListView(client: client, messages: messages)
                    .refreshable {
                        await loadMessages()
                    }
                    .task {
                        await loadMessages()
                    }
                    .task {
                        await streamMessages()
                    }
                MessageComposerView(onSend: sendMessage(text:))
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
        }
        .navigationTitle(displayName.resolvedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    func sendMessage(text: String) async {
        do {
            try await conversation.send(text: text)
        } catch {
            // TODO(elise): Toast error + optimistic upload
            print("Error sending message: \(error)")
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
            print("Error in message stream: \(error)")
        }
    }

    func loadMessages() async {
        do {
            let messages = try await conversation.messages()
            await MainActor.run {
                self.messages = messages
            }
        } catch {
            print("Error in detail messages \(conversation.peerAddress): \(error)")
        }
    }
}
