//
//  ConversationListView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/22/22.
//

import SwiftUI
import XMTP

struct ConversationListView: View {

    enum LoadingStatus {
        case loading, empty, success, error(String)
    }

    var client: XMTP.Client

    @State private var messagePreviews = [String: String]()

    @State private var conversations: [XMTP.Conversation] = []

    @State private var status: LoadingStatus = .loading

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
                            ConversationListItemView(
                                conversation: conversation,
                                messagePreview: messagePreviews[conversation.peerAddress] ?? ""
                            )
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

    func loadMostRecentMessage(conversation: Conversation) async -> DecodedMessage? {
        do {
            let messagePreview = try await conversation.messages(limit: 1)
            if !messagePreview.isEmpty {
                return messagePreview.first
            }
        } catch {
            print("Error loading message: \(conversation.peerAddress)")
        }
        return nil
    }

    func sortedConversations(conversations: [Conversation], messages: [String: DecodedMessage]) -> [Conversation] {
        var newConversations = conversations
        newConversations.sort {
            guard let message1Sent = messages[$0.peerAddress]?.sent else {
                return false
            }
            guard let message2Sent = messages[$1.peerAddress]?.sent else {
                return true
            }
            return message1Sent > message2Sent
        }
        return newConversations
    }

    func loadConversations() async {
        do {
            let newConversations = try await client.conversations.list()
            var newMessages = [String: DecodedMessage]()
            for conversation in newConversations {
                let message = await loadMostRecentMessage(conversation: conversation)
                messagePreviews[conversation.peerAddress] = try message?.content() ?? ""
                newMessages[conversation.peerAddress] = message
            }
            self.conversations = sortedConversations(conversations: newConversations, messages: newMessages)
            await MainActor.run {
                withAnimation {
                    self.status = .success
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

                let message = await loadMostRecentMessage(conversation: newConversation)
                let content = try message?.content() ?? ""
                messagePreviews[newConversation.peerAddress] = content

                await MainActor.run {
                    withAnimation {
                        if content.isEmpty {
                            conversations.insert(newConversation, at: conversations.endIndex)
                        } else {
                            conversations.insert(newConversation, at: 0)
                        }
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
