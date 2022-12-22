//
//  HomeView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import SwiftUI
import XMTP

struct HomeView: View {

    var client: XMTP.Client

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.edgesIgnoringSafeArea(.all)

                Text(client.address)
                    .padding()
                    .navigationBarTitle("home-title", displayMode: .inline)
            }
        }
    }
}
