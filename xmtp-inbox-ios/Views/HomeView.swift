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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.edgesIgnoringSafeArea(.all)

                ConversationListView(client: client)
                    .navigationBarTitle("home-title", displayMode: .inline)
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
