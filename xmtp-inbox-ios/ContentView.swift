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
        }.task {
            await loadClient()
        }
    }

    func loadClient() async {
        do {
            guard let keys = try Keystore.readKeys() else {
                return
            }
            let client = try Client.from(bundle: keys, options: .init(api: .init(env: Constants.xmtpEnv)))
            await MainActor.run {
                withAnimation {
                    self.status = .connected(client)
                }
            }
        } catch {
            print("Keystore read error: \(error.localizedDescription)")
        }
    }

    func generateWallet() {
        Task {
            do {
                await MainActor.run {
                    self.status = .connecting
                }
                let account = try PrivateKey.generate()
                let client = try await Client.create(account: account, options: .init(api: .init(env: Constants.xmtpEnv)))
                let keys = client.v1keys
                try Keystore.saveKeys(address: client.address, keys: keys)

                #if DEBUG
                UIPasteboard.general.string = client.address
                #endif

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
