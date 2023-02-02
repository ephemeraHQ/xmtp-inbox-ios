//
//  ConversationListView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/22/22.
//

import AlertToast
import SwiftUI
import web3
import XMTP

struct ConversationListView: View {
	enum LoadingStatus {
		case loading, empty, success, error(String)
	}

	let client: XMTP.Client

	@State private var ethClient: EthereumHttpClient?

	@State private var mostRecentMessages = [String: DecodedMessage]()

	@State private var displayNames = [String: DisplayName]()

	@State private var status: LoadingStatus = .loading

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
						NavigationLink(destination: ConversationDetailView(client: client, displayName: displayName(conversation), conversation: conversation)
						) {
							ConversationCellView(
								conversation: conversation,
								mostRecentMessage: mostRecentMessages[conversation.peerAddress],
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

	func displayName(_ conversation: DB.Conversation) -> DisplayName {
		return displayNames[conversation.peerAddress] ?? DisplayName(address: conversation.peerAddress)
	}

	func loadMostRecentMessage(conversation: DB.Conversation) async -> DecodedMessage? {
		do {
			let messagePreview = try await conversation.messages()
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
			// Fetch from the DB first
			try await conversationLoader.loadInitial()

			// Then fetch from the network
			try await conversationLoader.fetchInitial()

			var newMessages = [String: DecodedMessage]()
			for conversation in conversationLoader.conversations {
				let message = await loadMostRecentMessage(conversation: conversation)
				mostRecentMessages[conversation.peerAddress] = message
				newMessages[conversation.peerAddress] = message
			}

			// Asynchronously load ENS names for each conversation
			let newConversationAddresses = conversationLoader.conversations.map { EthereumAddress($0.peerAddress) }
			loadEnsNames(addresses: newConversationAddresses)

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
				let newConversation = try DB.Conversation.from(newConversation)

				let message = await loadMostRecentMessage(conversation: newConversation)
				mostRecentMessages[newConversation.peerAddress] = message
				loadEnsNames(addresses: [EthereumAddress(newConversation.peerAddress)])

				let content = try message?.content() ?? ""
				await MainActor.run {
					withAnimation {
						if content.isEmpty {
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

	func setupEthClient() throws -> EthereumHttpClient {
		guard let ethClient = ethClient else {
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
