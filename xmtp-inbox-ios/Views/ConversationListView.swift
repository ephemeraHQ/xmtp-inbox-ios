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

	func loadConversations() async {
		do {
			try await conversationLoader.load()

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
				var newConversation = try DB.Conversation.from(newConversation)

				loadEnsNames(addresses: [EthereumAddress(newConversation.peerAddress)])

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
