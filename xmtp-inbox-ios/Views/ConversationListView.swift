//
//  ConversationListView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/22/22.
//

import SwiftUI
import XMTP

struct ConversationListView: View {

    enum Status {
        case loading, empty, success, error(String)
    }

    var client: XMTP.Client

    @State private var status: Status = .loading

    @State private var conversations: [XMTP.Conversation] = []

    var body: some View {
        ZStack {
            switch status {
            case .loading:
                Text("loading")
            case .empty:
                Text("conversations-empty")
            case let .error(error):
                Text("Error: \(error)").foregroundColor(.actionNegative)
            case .success:
                List {
                    ForEach(conversations, id: \.peerAddress) { conversation in
                        NavigationLink(value: conversation) {
                            Text(conversation.peerAddress)
                        }
                    }
                    .listRowBackground(Color.backgroundPrimary)
                }
                .scrollContentBackground(.hidden)
                .navigationDestination(for: Conversation.self) { _ in
                    // TODO(elise): Open conversation detail
                }
                .refreshable {
                    await loadConversations()
                }
            }
        }
        .task {
            await loadConversations()
        }
        .task {
            await streamConversations()
        }
    }

    func loadConversations() async {
        do {
            let conversations = try await client.conversations.list()

            await MainActor.run {
                self.conversations = conversations
                self.status = conversations.isEmpty ? .empty : .success
            }
        } catch {
            debugPrint("Error loading conversations: \(error)")
            self.status = .error(error.localizedDescription)
        }
    }

    func streamConversations() async {
        do {
            for try await conversation in client.conversations.stream()

            where conversation.peerAddress != client.address {
                conversations.insert(conversation, at: 0)
                self.status = .success
            }
        } catch {
            debugPrint("Error streaming conversations: \(error)")
            if conversations.isEmpty {
                self.status = .error(error.localizedDescription)
            } else {
                // TODO(elise): Toast error
            }
        }
    }
}

struct ConversationListView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PreviewClientProvider { client in
                NavigationView {
                    ConversationListView(client: client)
                }
            }
        }
    }
}
