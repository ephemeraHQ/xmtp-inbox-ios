//
//  ContentView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import SwiftUI
import XMTP

class Auth: ObservableObject {

    enum AuthStatus {
        case loadingKeys, signedOut, tryingDemo, connecting, connected(Client)
    }

    @Published var status: AuthStatus = .loadingKeys

    func signOut() {
        do {
            try Keystore.deleteKeys()
            withAnimation {
                self.status = .signedOut
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct ContentView: View {

    @StateObject private var auth = Auth()

    var body: some View {
        ZStack {
            Color.backgroundPrimary.edgesIgnoringSafeArea(.all)

            switch auth.status {
            case .loadingKeys:
                ProgressView()
            case .signedOut, .tryingDemo:
                SplashView(isConnecting: false, onTryDemo: onTryDemo, onConnectWallet: onConnectWallet)
            case .connecting:
                SplashView(isConnecting: true, onTryDemo: onTryDemo, onConnectWallet: onConnectWallet)
            case let .connected(client):
                HomeView(client: client)
            }
        }
        .environmentObject(auth)
        .task {
            await loadClient()
        }
    }

    func loadClient() async {
        do {
            guard let keys = try Keystore.readKeys() else {
                await MainActor.run {
                    self.auth.status = .signedOut
                }
                return
            }
            let client = try Client.from(bundle: keys, options: .init(api: .init(env: Constants.xmtpEnv)))
            await MainActor.run {
                self.auth.status = .connected(client)
            }
        } catch {
            print("Keystore read error: \(error.localizedDescription)")
            await MainActor.run {
                self.auth.status = .signedOut
            }
        }
    }

    func onConnectWallet() {

    }

    func onTryDemo() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        self.auth.status = .tryingDemo
        Task {
            do {
                let account = try PrivateKey.generate()
                let client = try await Client.create(account: account, options: .init(api: .init(env: Constants.xmtpEnv)))
                let keys = client.v1keys
                try Keystore.saveKeys(address: client.address, keys: keys)

                await MainActor.run {
                    withAnimation {
                        self.auth.status = .connected(client)
                    }
                }
            } catch {
                await MainActor.run {
                    // TODO(elise): Toast error
                    print("Error generating random wallet: \(error)")
                    self.auth.status = .signedOut
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
