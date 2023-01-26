//
//  MessageListView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/5/22.
//

import SwiftUI
import XMTP

struct MessageListView: View {

    var client: Client

    var messages: [DecodedMessage]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    Spacer()
                    ForEach(Array(messages.sorted(by: { $0.sent < $1.sent }).enumerated()), id: \.0) { i, message in
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
    }
}
