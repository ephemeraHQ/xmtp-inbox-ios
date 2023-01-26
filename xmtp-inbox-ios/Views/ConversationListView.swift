//
//  ConversationListView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/22/22.
//

import SwiftUI
import XMTP
import web3
import AlertToast

struct ConversationListView: View {

    enum LoadingStatus {
        case loading, empty, success, error(String)
    }

    let client: XMTP.Client

    @State private var ethClient: EthereumHttpClient?

    @State private var messagePreviews = [String: String]()

    @State private var displayNames = [String: DisplayName]()

    @State private var conversations: [XMTP.Conversation] = []

    @State private var status: LoadingStatus = .loading

    @StateObject private var errorViewModel = ErrorViewModel()

    var body: some View {
        ZStack {
            switch status {
            case .loading:
                ProgressView()
            case .empty:
                Text("conversations-empty")
                    .padding()
            case let .error(errorMessage):
                Text(errorMessage)
                    .padding()
            case .success:
                List {
                    ForEach(conversations, id: \.topic) { conversation in
                        NavigationLink(destination: ConversationDetailView(client: client, displayName: displayName(conversation), conversation: conversation)
                        ) {
                            ConversationCellView(
                                conversation: conversation,
                                messagePreview: messagePreviews[conversation.peerAddress] ?? "",
                                displayName: displayName(conversation)
                            )
                        }
                    }
                    .listRowBackground(Color.backgroundPrimary)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical)
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    await loadConversations()
                }
            }
        }
        .onAppear {
            Task.detached {
                await loadConversations()
            }
        }
        .task {
            await streamConversations()
        }
        .toast(isPresenting: $errorViewModel.isShowing) {
            AlertToast.error(errorViewModel.errorMessage)
        }
    }

    func displayName(_ conversation: Conversation) -> DisplayName {
        return displayNames[conversation.peerAddress] ?? DisplayName(address: conversation.peerAddress)
    }

    func loadMostRecentMessage(conversation: Conversation) async -> DecodedMessage? {
        do {
            let messagePreview = try await conversation.messages(limit: 1)
            if !messagePreview.isEmpty {
                return messagePreview.first
            }
        } catch {
            print("Error loading message: \(error)")
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

            // Asynchronously load ENS names for each conversation
            let newConversationAddresses = newConversations.map {EthereumAddress($0.peerAddress)}
            loadEnsNames(addresses: newConversationAddresses)

            self.conversations = sortedConversations(conversations: newConversations, messages: newMessages)
            await MainActor.run {
                withAnimation {
                    if self.conversations.isEmpty {
                        self.status = .empty
                    } else {
                        self.status = .success
                    }
                }
            }
        } catch {
            await MainActor.run {
                if conversations.isEmpty {
                    self.status = .error(error.localizedDescription)
                } else {
                    self.errorViewModel.showError("Error loading conversations: \(error)")
                }
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
                loadEnsNames(addresses: [EthereumAddress(newConversation.peerAddress)])

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
            await MainActor.run {
                if conversations.isEmpty {
                    self.status = .error(error.localizedDescription)
                } else {
                    self.errorViewModel.showError("Error streaming conversations: \(error)")
                }
            }
        }
    }

    func setupEthClient() throws -> EthereumHttpClient {
        guard let ethClient = self.ethClient else {
            guard let infuraUrl = Constants.infuraUrl else {
                throw EnsError.invalidURL
            }
            let newEthClient = EthereumHttpClient(url: infuraUrl, network: .mainnet)
            self.ethClient = newEthClient
            return newEthClient
        }
        return ethClient
    }

    func loadEnsNames(addresses: [EthereumAddress]) {
        Task {
            do {
                let ethClient = try setupEthClient()
                let nameService = EthereumNameService(client: ethClient)

                let results = try await nameService.resolve(addresses: addresses)
                for result in results {
                    guard case let .resolved(value) = result.output else {
                        continue
                    }
                    let address = result.address.toChecksumAddress()
                    self.displayNames[address] = DisplayName(ensName: value, address: address)
                }
            } catch {
                print("Error resolving ENS names: \(error)")
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
