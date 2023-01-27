//
//  SettingsView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/26/23.
//

import SwiftUI
import XMTP

struct SettingsView: View {

    let client: Client

    @EnvironmentObject var auth: Auth

    @State private var showSignOutAlert = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                HStack {
                    Text("Address:")
                        .bold()
                    Text(client.address.truncatedAddress())
                }
                .onTapGesture(perform: onCopyAddress)
                .padding(.top)
                .padding(.horizontal)
                HStack {
                    Text("XMTP Environment:")
                        .bold()
                    Text(Constants.xmtpEnv == .production ? "production" : "dev")
                }
                .padding(.horizontal)
                HStack {
                    Text("Infura Key:")
                        .bold()
                    Text(Constants.hasInfuraKey ? "YES" : "NO")
                }
                .padding(.horizontal)
                HStack {
                    Text("Version:")
                        .bold()
                    Text(version)
                }
                .padding(.horizontal)
                Spacer()
                Button(action: onSignOut) {
                    Text("sign-out")
                        .kerning(0.5)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: 58)
                        .background(Color.backgroundSecondary)
                        .font(.H1)
                        .clipShape(Capsule())
                        .padding()
                }
            }
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("sign-out-cta", isPresented: $showSignOutAlert) {
                Button("cancel", role: .cancel) { }
                Button("sign-out", role: .destructive) {
                    auth.signOut()
                }
            }
        }
    }

    func onSignOut() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        showSignOutAlert.toggle()
    }

    func onCopyAddress() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        UIPasteboard.general.string = client.address
    }

    var version: String {
        "\(Constants.version) (\(Constants.buildNumber))"
    }
}
