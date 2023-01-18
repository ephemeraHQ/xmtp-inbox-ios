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
        case unknown, connecting, connected(Client), error(String)
    }

    @Published var status: AuthStatus = .unknown

    func signOut() {
        do {
            try Keystore.deleteKeys()
            withAnimation {
                self.status = .unknown
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
            case .unknown:
                SplashView(isLoading: false, onNewDemo: onNewDemo)
            case .connecting:
                SplashView(isLoading: true, onNewDemo: onNewDemo)
            case let .connected(client):
                HomeView(client: client)
            case let .error(error):
                Text("Error: \(error)").foregroundColor(.actionNegative)
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
                return
            }
            let client = try Client.from(bundle: keys, options: .init(api: .init(env: Constants.xmtpEnv)))
            await MainActor.run {
                self.auth.status = .connected(client)
            }
        } catch {
            print("Keystore read error: \(error.localizedDescription)")
        }
    }

    func onNewDemo() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        self.auth.status = .connecting
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
                    self.auth.status = .error("Error generating wallet: \(error)")
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
