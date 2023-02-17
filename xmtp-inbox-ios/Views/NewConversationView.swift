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

	@StateObject var contactFinder: ContactFinder

	init(client: XMTP.Client, onCreate: @escaping (DB.Conversation) -> Void) {
		self.client = client
		self.onCreate = onCreate
		_contactFinder = StateObject(wrappedValue: ContactFinder(client: client))
	}

	var body: some View {
		NavigationView {
			ZStack {
				Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
				List {
					TextField("new-message-prompt", text: $contactFinder.searchText)
						.autocorrectionDisabled(true)
						.autocapitalization(.none)
						.focused($isFocused)
						.onAppear {
							self.isFocused = true
						}
					if let error = contactFinder.error {
						Text(error)
							.font(.Body2)
							.foregroundColor(.actionNegative)
					} else {
						ForEach(contactFinder.results) { result in
							Button {
								createConversation(address: result.address)
							} label: {
								HStack {
									EnsImageView(imageSize: 48, peerAddress: result.address)
										.padding(.trailing, 8)
									VStack(alignment: .leading) {
										Text(result.address.truncatedAddress())
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

	func createConversation(address: String) {
		Task {
			do {
				var client = client
				let conversation = try await client.conversations.newConversation(with: address)
				let newConversation = try await DB.Conversation.from(conversation)
				await MainActor.run {
					dismiss()
					onCreate(newConversation)
				}
			} catch ConversationError.recipientNotOnNetwork {
				await MainActor.run {
					withAnimation {
						contactFinder.error = NSLocalizedString("not-on-network-error", comment: "")
					}
				}
			} catch {
				await MainActor.run {
					withAnimation {
						contactFinder.error = error.localizedDescription
					}
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
