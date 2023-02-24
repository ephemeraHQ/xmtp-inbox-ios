//
//  ConversationListView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/22/22.
//

import GRDBQuery
import SwiftUI
import XMTP
import Combine

struct ConversationListView: View {
	enum LoadingStatus {
		case loading, empty, success, error(String)
	}

	let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
	@State @MainActor var isLoading = false

	let client: XMTP.Client

	@State private var status: LoadingStatus = .success
	@State var isShowingNewMessage = false


	@EnvironmentObject var coordinator: EnvironmentCoordinator
	@StateObject private var conversationLoader: ConversationLoader

	@Query(ConversationsRequest(), in: \.dbQueue) var conversations: [DB.Conversation]

	init(client: XMTP.Client) {
		let conversationLoader = ConversationLoader(client: client)

		self.client = client
		_conversationLoader = StateObject(wrappedValue: conversationLoader)
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
					ForEach(conversations, id: \.id) { conversation in
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
		.onAppear {
			timer.upstream.connect()
			Task.detached {
				await loadConversations()
			}
		}
		.onDisappear {
			timer.upstream.connect().cancel()
		}
		.onReceive(timer) { _ in
			if isLoading {
				return
			}

			Task {
				await loadConversations()
			}
		}
		.task {
			await streamConversations()
		}
		.sheet(isPresented: $isShowingNewMessage) {
			NewConversationView(client: client) { conversation in
				coordinator.path.append(conversation)
			}
		}
	}

	func loadConversations() async {
		print("load conversations called")
		if isLoading {
			return
		}

		do {
			await MainActor.run {
				withAnimation {
					if conversations.isEmpty {
						self.status = .loading
						self.isLoading = true
					}
				}
			}

			try await conversationLoader.load()

			await MainActor.run {
				self.isLoading = false
				withAnimation {
					if conversations.isEmpty {
						self.status = .empty
					} else {
						self.status = .success
					}
				}
			}
		} catch {
			print("ERROR LOADING CONVERSATIONS \(error)")
			await MainActor.run {
				if conversations.isEmpty {
					self.status = .error(error.localizedDescription)
					self.isLoading = false
				} else {
					self.isLoading = false
					Flash.add(.error("Error loading conversations: \(error)"))
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
				try await newConversation.loadMostRecentMessages(client: client)
			}
		} catch {
			await MainActor.run {
				if conversations.isEmpty {
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
