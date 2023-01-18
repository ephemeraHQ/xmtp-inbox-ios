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
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            ZStack {
                                HStack {
                                    EnsImageView(imageSize: 40.0, peerAddress: client.address)
                                        .onLongPressGesture {
                                            // TODO(elise): Try on device
                                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                            auth.signOut()
                                        }
                                    Spacer()
                                }
                                HStack {
                                    Image("MessageIcon")
                                        .renderingMode(.template)
                                        .colorMultiply(.textPrimary)
                                        .frame(width: 16.0, height: 16.0)
                                    Text("home-title").font(.Title2H)
                                }
                                .onLongPressGesture {
                                    #if DEBUG
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    UIPasteboard.general.string = client.address
                                    #endif
                                }
                            }
                        }
                    }
            }
        }
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
