//
//  ConversationListView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/22/22.
//

import SwiftUI
import XMTP

struct ConversationListView: View {

    var client: XMTP.Client

    @State private var status: LoadingStatus = .loading

    @State private var conversations: [XMTP.Conversation] = []

    var body: some View {
        ZStack {
            switch status {
            case .loading:
                ProgressView()
            case .empty:
                Text("conversations-empty")
            case let .error(error):
                Text("Error: \(error)").foregroundColor(.actionNegative)
            case .success:
                List {
                    ForEach(conversations, id: \.peerAddress) { conversation in
                        NavigationLink(value: conversation) {
                            ConversationListItemView(conversation: conversation)
                        }
                    }
                    .listRowBackground(Color.backgroundPrimary)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical)
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
            let newConversations = try await client.conversations.list()

            await MainActor.run {
                withAnimation {
                    self.conversations = newConversations
                    self.status = conversations.isEmpty ? .empty : .success
                }
            }
        } catch {
            print("Error loading conversations: \(error)")
            await MainActor.run {
                self.status = .error(error.localizedDescription)
            }
        }
    }

    func streamConversations() async {
        do {
            for try await newConversation in client.conversations.stream()
            where newConversation.peerAddress != client.address {
                await MainActor.run {
                    withAnimation {
                        conversations.insert(newConversation, at: 0)
                        self.status = .success
                    }
                }
            }
        } catch {
            print("Error streaming conversations: \(error)")
            if conversations.isEmpty {
                await MainActor.run {
                    self.status = .error(error.localizedDescription)
                }
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
