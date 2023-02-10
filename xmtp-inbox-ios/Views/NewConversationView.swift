//
//  NewConversationView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 2/10/23.
//

import AlertToast
import Combine
import SwiftUI
import XMTP

struct NewConversationView: View {
	let client: XMTP.Client
	var onCreate: (DB.Conversation) -> Void
	let searchTextPublisher = PassthroughSubject<String, Never>()

	@Environment(\.dismiss) var dismiss
	@FocusState var isFocused
	@State private var searchText = ""
	@State private var searchResults = [String]()
	@State private var error: String?

	var body: some View {
		NavigationView {
			ZStack {
				Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
				List {
					TextField("new-message-prompt", text: $searchText)
						.focused($isFocused)
						.onAppear {
							self.isFocused = true
						}
						.onChange(of: searchText) { searchText in
							searchTextPublisher.send(searchText)
						}
						.onReceive(
							searchTextPublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
						) { debouncedText in
							validateSearch(debouncedText)
						}
					if let error {
						Text(error)
							.font(.Body2)
							.foregroundColor(.actionNegative)
					}
					ForEach(searchResults, id: \.self) { address in
						Button {
							createConversation(address: address)
						} label: {
							HStack {
								EnsImageView(imageSize: 48, peerAddress: address)
									.padding(.trailing, 8)
								VStack(alignment: .leading) {
									Text(address.truncatedAddress())
										.font(.Body1B)
										.padding(.bottom, 1)
										.foregroundColor(.textPrimary)
									Text("valid-ethereum-address")
										.font(.Body2)
										.foregroundColor(.textScondary)
								}
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
		.presentationDetents([.height(240)])
	}

	func validateSearch(_ debouncedText: String) {
		do {
			error = nil
			let range = NSRange(location: 0, length: debouncedText.utf16.count)
			let regex = try NSRegularExpression(pattern: "^0x[a-fA-F0-9]{40}$")
			if regex.firstMatch(in: debouncedText, options: [], range: range) != nil {
				searchResults = [debouncedText]
			} else {
				searchResults = []
				if !debouncedText.isEmpty {
					error = NSLocalizedString("invalid-ethereum-address", comment: "")
				}
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
					self.error = NSLocalizedString("not-on-network-error", comment: "")
				}
			} catch {
				await MainActor.run {
					self.error = error.localizedDescription
				}
			}
		}
	}
}

struct NewConversationView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			PreviewClientProvider { client in
				NewConversationView(client: client) { _ in
					// New conversation
				}
			}
		}
	}
}
