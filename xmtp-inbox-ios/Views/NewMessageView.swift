//
//  NewMessageView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 2/10/23.
//

import SwiftUI
import XMTP
import Combine
import AlertToast

struct NewMessageView: View {
    let client: XMTP.Client
    var onCreate: (DB.Conversation) -> Void
    let searchTextPublisher = PassthroughSubject<String, Never>()

    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResults = [String]()
    @State private var errorViewModel = ErrorViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
                List {
                    ForEach(searchResults, id: \.self) { address in
                        Button {
                            createConversation(address: address)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(address.truncatedAddress())
                                    .font(.Body1B)
                                    .padding(.bottom, 1)
                                Text("valid-ethereum-address")
                                    .font(.Body2)
                                    .foregroundColor(.textScondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("new-message")
            .navigationBarItems(trailing: Button {
                dismiss()
            } label: {
                Image("XIcon")
                    .renderingMode(.template)
                    .colorMultiply(.textPrimary)
            })
            .navigationBarTitleDisplayMode(.inline)
        }
        .searchable(text: $searchText, prompt: "new-message-prompt")
        .onChange(of: searchText) { searchText in
            searchTextPublisher.send(searchText)
        }
        .onReceive(
            searchTextPublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
        ) { debouncedText in
            validateSearch(debouncedText)
        }
        .toast(isPresenting: $errorViewModel.isShowing) {
            AlertToast.error(errorViewModel.errorMessage)
        }
    }

    func validateSearch(_ debouncedText: String) {
        do {
            let range = NSRange(location: 0, length: debouncedText.utf16.count)
            let regex = try NSRegularExpression(pattern: "^0x[a-fA-F0-9]{40}$")
            if regex.firstMatch(in: debouncedText, options: [], range: range) != nil {
                // TODO: Check if the address is on the XMTP network.
                self.searchResults = [debouncedText]
            } else {
                self.searchResults = []
            }
        } catch {
            print("Error searching: \(error)")
        }
    }

    func createConversation(address: String) {
        Task {
            do {
                let conversation = try await client.conversations.newConversation(with: address)
                let newConversation = try await DB.Conversation.from(conversation)
                await MainActor.run {
                    dismiss()
                    onCreate(newConversation)
                }
            } catch ConversationError.recipientNotOnNetwork {
                await MainActor.run {
                    self.errorViewModel.showError("not-on-network-error")
                }
            } catch {
                await MainActor.run {
                    self.errorViewModel.showError(error.localizedDescription)
                }
            }
        }
    }
}
