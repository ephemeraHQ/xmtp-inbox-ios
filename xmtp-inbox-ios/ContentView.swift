//
//  ContentView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import SwiftUI
import XMTP

struct ContentView: View {

    enum AuthStatus {
        case unknown, connecting, connected(Client), error(String)
    }

    @State private var status: AuthStatus = .unknown

    var body: some View {
        ZStack {
            Color.backgroundPrimary.edgesIgnoringSafeArea(.all)

            switch status {
            case .unknown:
                SplashView(isLoading: false, onNewDemo: generateWallet)
            case .connecting:
                SplashView(isLoading: true, onNewDemo: generateWallet)
            case let .connected(client):
                HomeView(client: client)
            case let .error(error):
                Text("Error: \(error)").foregroundColor(.actionNegative)
            }
        }
    }

    func generateWallet() {
        Task {
            do {
                await MainActor.run {
                    self.status = .connecting
                }
                let wallet = try PrivateKey.generate()
                let client = try await Client.create(account: wallet)

                await MainActor.run {
                    withAnimation {
                        self.status = .connected(client)
                    }
                }
            } catch {
                await MainActor.run {
                    self.status = .error("Error generating wallet: \(error)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
