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

    var client: XMTP.Client

    @StateObject var environmentCoordinator = EnvironmentCoordinator()

    @EnvironmentObject var auth: Auth

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
                ConversationListView(client: client)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
                EnsImageView(imageSize: 40.0, peerAddress: client.address)
                    .onLongPressGesture {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        auth.signOut()
                    }
            )
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
                    #if DEBUG
                    .onLongPressGesture {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        UIPasteboard.general.string = client.address
                    }
                    #endif
                }
            }
        }
        .accentColor(.textPrimary)
        .environmentObject(environmentCoordinator)
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
