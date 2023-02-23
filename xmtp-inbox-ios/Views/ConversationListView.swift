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

	let client: XMTP.Client
	let observer: MessageObserver!

	@State private var mostRecentMessages = [String: DecodedMessage]()
	@State private var status: LoadingStatus = .success
	@State var isShowingNewMessage = false

	@EnvironmentObject var coordinator: EnvironmentCoordinator
	@StateObject private var conversationLoader: ConversationLoader

	init(client: XMTP.Client) {
		let conversationLoader = ConversationLoader(client: client)

		self.client = client
		_conversationLoader = StateObject(wrappedValue: conversationLoader)

		observer = MessageObserver {
			Task {
				try await Task.sleep(for: .milliseconds(500))
				try await conversationLoader.fetchLocal()
			}
		}

		do {
			try DB.read { db in
				db.add(transactionObserver: observer)
			}
		} catch {
			print("Error adding observer \(error)")
		}
	}

	var body: some View {
		ZStack {
			switch status {
			case .loading:
				ProgressView()
			case .empty:
				if let error = conversationLoader.error {
					Text(error.localizedDescription)
				} else {
					Text("conversations-empty")
						.padding()
				}
			case let .error(errorMessage):
				Text(errorMessage)
					.padding()
			case .success:
				List {
					ForEach(conversationLoader.conversations, id: \.id) { conversation in
						Button(action: {
							coordinator.path.append(conversation)
						}) {
							ConversationCellView(conversation: conversation)
								.padding(.horizontal, 8)
						}
					}
					.listRowBackground(Color.backgroundPrimary)
					.listRowInsets(EdgeInsets())
					.padding(.vertical)
				}
				.listStyle(.plain)
				.scrollContentBackground(.hidden)
				.refreshable {
					await loadConversations()
				}
			}
			VStack {
				Spacer()
				HStack {
					Spacer()
					FloatingButton(icon: Image("PlusIcon")) {
						isShowingNewMessage.toggle()
					}
					.padding(24)
				}
			}
			.frame(maxWidth: .infinity)
			.frame(maxHeight: .infinity)
		}
		.navigationDestination(for: DB.Conversation.self) { conversation in
			ConversationDetailView(client: client, conversation: conversation)
		}
		.task {
			await loadConversations()
		}
		.task {
			await streamConversations()
		}
		.sheet(isPresented: $isShowingNewMessage) {
			NewConversationView(client: client) { conversation in
				conversationLoader.insertConversation(conversation, at: conversationLoader.conversations.endIndex)
				coordinator.path.append(conversation)
			}
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
					Flash.add(.error("Error loading conversations: \(error)"))
				}
			}
		}

		// swiftlint:disable no_optional_try
		try? await Task.sleep(for: .seconds(5))

		await loadConversations()
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
							conversationLoader.insertConversation(newConversation, at: conversationLoader.conversations.endIndex)
						} else {
							conversationLoader.insertConversation(newConversation, at: 0)
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
					Flash.add(.error("Error streaming conversations: \(error)"))
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
