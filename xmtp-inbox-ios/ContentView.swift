//
//  ContentView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import SwiftUI
import XMTP

struct ContentView: View {
	@StateObject private var environmentCoordinator = EnvironmentCoordinator()
	@StateObject private var auth: Auth = .init()

	@State private var wcUrl: URL?

	var body: some View {
		FullScreenContentProvider {
			FlashProvider {
				ZStack {
					Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
					switch auth.status {
					case let .connected(client):
						HomeView(client: client)
					case .connecting:
						ProgressView("Awaiting signatures…")
					case .loadingKeys:
						ProgressView("Loading keys…")
					default:
						SplashView(onTryDemo: onTryDemo, onConnecting: onConnecting, onConnected: onConnectWallet)
					}
				}
			}
			.sheet(isPresented: $auth.isShowingQRCode) {
				if let wcUrl {
					QRCodeView(data: Data(wcUrl.absoluteString.utf8))
				} else {
					Text("Cannot connect to wallet.")
				}
			}
			.environmentObject(environmentCoordinator)
			.environmentObject(auth)
			.task {
				await loadClient()
			}
		}
	}

	func onConnecting() {
		withAnimation {
			auth.status = .connecting
		}
	}

	func loadClient() async {
		print("Load client")
		do {
			guard let keys = try Keystore.readKeys() else {
				await MainActor.run {
					auth.status = .signedOut
				}
				return
			}
			let client = try Client.from(v1Bundle: keys, options: .init(api: .init(env: Constants.xmtpEnv)))
			await MainActor.run {
				print("Connected")
				auth.status = .connected(client)
			}
		} catch {
			print("Keystore read error: \(error.localizedDescription)")
			await MainActor.run {
				auth.status = .signedOut
			}
		}
	}

	func onConnectWallet(client: Client) {
		do {
			let keys = client.v1keys
			try Keystore.saveKeys(address: client.address, keys: keys)
		} catch {
			print("Error saving keys: \(error)")
		}

		withAnimation {
			auth.status = .connected(client)
		}
	}

	func onTryDemo() {
		UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
		auth.status = .tryingDemo
		Task {
			do {
				let account = try PrivateKey.generate()
				let client = try await Client.create(account: account, options: .init(api: .init(env: Constants.xmtpEnv)))
				let keys = client.v1keys
				try Keystore.saveKeys(address: client.address, keys: keys)

				await MainActor.run {
					withAnimation {
						auth.status = .connected(client)
					}
				}
			} catch {
				await MainActor.run {
					auth.status = .signedOut
					Flash.add(.error("Error generating random wallet: \(error)"))
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
