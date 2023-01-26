//
//  ConversationDetailView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import SwiftUI
import XMTP
import AlertToast

struct ConversationDetailView: View {

    let client: XMTP.Client

    let displayName: DisplayName

    let conversation: XMTP.Conversation

    @State private var messages: [DecodedMessage] = []

    @State private var errorViewModel = ErrorViewModel()

    var body: some View {
        ZStack {
            Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
            VStack {
                // TODO(elise): Paginate list of messages and migrate fetch into MessageListView
                // to match ConversationListView.
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
        .toast(isPresenting: $errorViewModel.isShowing) {
            AlertToast.error(errorViewModel.errorMessage)
        }
    }

    func sendMessage(text: String) async {
        do {
            // TODO(elise): Optimistic upload / undo
            try await conversation.send(text: text)
        } catch {
            self.errorViewModel.showError("Error sending message: \(error)")
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
