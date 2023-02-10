//
//  HomeView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import SwiftUI
import XMTP

class EnvironmentCoordinator: ObservableObject {
	@Published var path = NavigationPath()
}

struct HomeView: View {
	let client: XMTP.Client

	@State var isShowingAccount = false

	@StateObject var environmentCoordinator = EnvironmentCoordinator()

	var body: some View {
		NavigationStack {
			ZStack {
				Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
				ConversationListView(client: client)
				#if DEBUG
					VStack {
						Spacer()
						HStack {
							Spacer()
							FloatingButton(icon: Image("PlusIcon"), action: onNewMessage)
								.padding(24)
						}
					}
				#endif
			}
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarItems(leading: HapticButton {
				isShowingAccount.toggle()
			} label: {
				EnsImageView(imageSize: 40.0, peerAddress: client.address)
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
		.environmentObject(environmentCoordinator)
		.sheet(isPresented: $isShowingAccount) {
			AccountView(client: client)
		}
	}
}

func onNewMessage() {
	// TODO(elise): Add new message modal
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
