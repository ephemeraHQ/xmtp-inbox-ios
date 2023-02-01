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

    @State private var errorViewModel = ErrorViewModel()

    var body: some View {
        ZStack {
            Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
            VStack {
                MessageListView(client: client, conversation: conversation)
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
            await MainActor.run {
                self.errorViewModel.showError("Error sending message: \(error)")
            }
        }
    }
}
