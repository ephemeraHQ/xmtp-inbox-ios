//
//  MessageComposerView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import SwiftUI
import XMTP

struct MessageComposerView: View {

    @State private var text: String = ""

    @State private var isSending = false

    @FocusState var isFocused

    var onSend: (String) async -> Void

    var body: some View {
        HStack {
            TextField("Type a message…", text: $text, axis: .vertical)
                .focused($isFocused)
                .lineLimit(4)
                .padding(12)
                .onSubmit {
                    send()
                }
                .onAppear {
                    UIView.setAnimationsEnabled(false)
                    self.isFocused = true
                    UIView.setAnimationsEnabled(true)
                }
            ZStack {
                Color.actionPrimary
                    .frame(width: 32, height: 32)
                    .roundCorners(16, corners: [.topLeft, .topRight, .bottomLeft])
                Button(action: send) {
                    Label("Send", systemImage: "arrow.up")
                        .font(.system(size: 16))
                        .labelStyle(.iconOnly)
                        .foregroundColor(Color.actionPrimaryText)
                }
            }
        }
        .padding(.horizontal, 8)
        .overlay(RoundedCorner(radius: 16, corners: [.topLeft, .topRight, .bottomLeft]).stroke(Color.actionPrimary, lineWidth: 2))
        .disabled(isSending)
    }

    func send() {
        if text.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return
        }

        isSending = true
        Task {
            await onSend(text)
            await MainActor.run {
                self.text = ""
                self.isSending = false
                self.isFocused = true
            }
        }
    }
}

struct MessageComposerView_Previews: PreviewProvider {
    static var previews: some View {
        MessageComposerView { _ in }
    }
}
