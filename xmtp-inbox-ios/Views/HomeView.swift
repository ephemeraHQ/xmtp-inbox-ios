//
//  HomeView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import GRDB
import SwiftUI
import XMTP

// swiftlint:disable force_try

struct SingleColumnView: View {
	let client: XMTP.Client
	@State var isShowingAccount = false
	@State var dbQueue: DatabaseQueue = try! DatabaseQueue(named: "single")

	@EnvironmentObject var environmentCoordinator: EnvironmentCoordinator
	@Environment(\.db) var db

	var body: some View {
		NavigationStack(path: $environmentCoordinator.path) {
			ZStack {
				Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
				ConversationListView(client: client, db: db)
			}
			.navigationDestination(for: DB.Conversation.self) { conversation in
				ConversationDetailView(client: client, conversation: conversation)
			}
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarItems(leading: HapticButton {
				isShowingAccount.toggle()
			} label: {
				AvatarView(imageSize: 40.0, peerAddress: client.address)
			})
			.toolbar {
				ToolbarItem(placement: .principal) {
					HStack {
						Image("MessageIcon")
							.renderingMode(.template)
							.colorMultiply(.textPrimary)
							.frame(width: 16.0, height: 16.0)
						Text("home-title").font(.Title2H)
							.accessibilityAddTraits(.isHeader)
							.fixedSize(horizontal: true, vertical: false)
					}
				}
			}
		}
		.accentColor(.textPrimary)
		.sheet(isPresented: $isShowingAccount) {
			AccountView(client: client)
		}
	}
}

struct SplitColumnView: View {
	let client: XMTP.Client
	@State var dbQueue: DatabaseQueue = try! DatabaseQueue(named: "split")
	@State var selectedConversation: DB.Conversation?
	@State var isShowingAccount = false

	@EnvironmentObject var environmentCoordinator: EnvironmentCoordinator
	@Environment(\.db) var db

	var body: some View {
		NavigationSplitView(sidebar: {
			ConversationListView(client: client, selectedConversation: $selectedConversation, db: db)
				.toolbar {
					ToolbarItem(placement: .automatic) {
						HapticButton {
							isShowingAccount.toggle()
						} label: {
							AvatarView(imageSize: 40.0, peerAddress: client.address)
						}
					}
				}
		}, detail: {
			ZStack {
				if let selectedConversation {
					ConversationDetailView(client: client, conversation: selectedConversation)
						.id(selectedConversation.id)
				} else {
					Text("Select a conversation…")
						.foregroundColor(.secondary)
				}
			}
		})
		.navigationBarTitleDisplayMode(.inline)
		.accentColor(.textPrimary)
		.sheet(isPresented: $isShowingAccount) {
			AccountView(client: client)
		}
	}
}

class EnvironmentCoordinator: ObservableObject {
	@Published var path = NavigationPath()
}

struct HomeView: View {
	let client: XMTP.Client

	@Environment(\.db) var db

	init(client: XMTP.Client) {
		self.client = client
	}

	var body: some View {
		DBProvider(client: client) {
			ViewThatFits {
				SplitColumnView(client: client)
				SingleColumnView(client: client)
			}
			.task {
				do {
					try await XMTPPush.shared.request()
				} catch {
					print("Error request push notification access")
				}
			}
		}
	}
}

struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		ZStack {
			PreviewClientProvider { client in
				HomeView(client: client)
			}
		}
	}
}
