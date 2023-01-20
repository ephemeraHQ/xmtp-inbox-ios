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

    @State private var wcUrl: URL?

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
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // If already connecting, bounce back out to the WalletConnect URL
        if case .connecting = auth.status {
            // swiftlint:disable force_unwrapping
            if self.wcUrl != nil && UIApplication.shared.canOpenURL(wcUrl!) {
                UIApplication.shared.open(wcUrl!)
                return
            }
            // swiftlint:enable force_unwrapping
        }

        self.auth.status = .connecting
        Task {
            do {
                let account = try Account.create()
                let url = try account.wcUrl()
                self.wcUrl = url
                await UIApplication.shared.open(url)

                try await account.connect()
                for _ in 0 ... 30 {
                    if account.isConnected {
                        let client = try await Client.create(account: account, options: .init(api: .init(env: Constants.xmtpEnv)))
                        let keys = client.v1keys
                        try Keystore.saveKeys(address: client.address, keys: keys)

                        await MainActor.run {
                            withAnimation {
                                self.auth.status = .connected(client)
                            }
                        }
                        return
                    }

                    try await Task.sleep(for: .seconds(1))
                }
                await MainActor.run {
                    // TODO(elise): Toast error
                    print("Timed out waiting to connect (30 seconds)")
                    self.auth.status = .signedOut
                }
            } catch {
                await MainActor.run {
                    // TODO(elise): Toast error
                    print("Error connecting: \(error)")
                    self.auth.status = .signedOut
                }
            }
        }
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
