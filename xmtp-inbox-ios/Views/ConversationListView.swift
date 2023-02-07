//
//  ConversationListView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/22/22.
//

import AlertToast
import SwiftUI
import XMTP

struct ConversationListView: View {
	enum LoadingStatus {
		case loading, empty, success, error(String)
	}

	let client: XMTP.Client

	@State private var mostRecentMessages = [String: DecodedMessage]()
	@State private var status: LoadingStatus = .success

	@StateObject private var errorViewModel = ErrorViewModel()
	@StateObject private var conversationLoader: ConversationLoader

	init(client: XMTP.Client) {
		self.client = client
		_conversationLoader = StateObject(wrappedValue: ConversationLoader(client: client))
	}

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
					ForEach(conversationLoader.conversations, id: \.id) { conversation in
						NavigationLink(destination: ConversationDetailView(client: client, conversation: conversation)
						) {
							ConversationCellView(conversation: conversation)
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
		.task {
			await loadConversations()
		}
		.task {
			await streamConversations()
		}
		.toast(isPresenting: $errorViewModel.isShowing) {
			AlertToast.error(errorViewModel.errorMessage)
		}
	}

	func loadConversations() async {
		do {
			await MainActor.run {
				withAnimation {
					if conversationLoader.conversations.isEmpty {
						self.status = .loading
					}
				}
			}

			try await conversationLoader.load()

			await MainActor.run {
				withAnimation {
					if conversationLoader.conversations.isEmpty {
						self.status = .empty
					} else {
						self.status = .success
					}
				}
			}
		} catch {
			print("ERROR LOADING CONVERSATIONS \(error)")
			await MainActor.run {
				if conversationLoader.conversations.isEmpty {
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
				where newConversation.peerAddress != client.address
			{
				var newConversation = try await DB.Conversation.from(newConversation)

				try await newConversation.loadMostRecentMessage(client: client)

				await MainActor.run {
					withAnimation {
						if newConversation.lastMessage == nil {
							conversationLoader.conversations.insert(newConversation, at: conversationLoader.conversations.endIndex)
						} else {
							conversationLoader.conversations.insert(newConversation, at: 0)
						}
						self.status = .success
					}
				}
			}
		} catch {
			await MainActor.run {
				if conversationLoader.conversations.isEmpty {
					self.status = .error(error.localizedDescription)
				} else {
					self.errorViewModel.showError("Error streaming conversations: \(error)")
				}
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
