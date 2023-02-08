//
//  ContentView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import AlertToast
import SwiftUI
import Web3Wallet
import XMTP

struct ContentView: View {
	@StateObject private var auth = Auth()

	@State private var wcUrl: WalletConnectURI?

	@StateObject private var errorViewModel = ErrorViewModel()

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
		.toast(isPresenting: $errorViewModel.isShowing, duration: 10) {
			AlertToast.error(errorViewModel.errorMessage)
		}
		.sheet(isPresented: $auth.isShowingQRCode) {
			if let wcUrl {
				QRCodeView(data: Data(wcUrl.absoluteString.utf8))
			} else {
				Text("Cannot connect to wallet.")
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
			let client = try Client.from(v1Bundle: keys, options: .init(api: .init(env: Constants.xmtpEnv)))
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

//		// If already connecting, bounce back out to the WalletConnect URL
//		if case .connecting = auth.status {
//			// swiftlint:disable force_unwrapping
//			if self.wcUrl != nil && UIApplication.shared.canOpenURL(wcUrl!) {
//				UIApplication.shared.open(wcUrl!)
//				return
//			}
//			// swiftlint:enable force_unwrapping
//		}

		auth.status = .connecting
		Task {
			do {
				print("Configuring")
				WCWalletConnection.configure()
				print("Configured connection")

				let uri = try await Pair.instance.create()
				print("URI is \(uri)")

				// swiftlint:disable force_try
				let url = URL(string: "\(uri.absoluteString)")!
				print("URL IS \(url)")


				await MainActor.run {
					self.wcUrl = uri
					auth.isShowingQRCode = !UIApplication.shared.canOpenURL(url)
				}


			let namespaces: [String: ProposalNamespace] = [
					"eip155": ProposalNamespace(
						chains: [Blockchain("eip155:1")!],
						methods: ["personal_sign"],
						events: ["any"]
					),
				]

				try await Sign.instance.connect(requiredNamespaces: namespaces, topic: uri.topic)

//				await UIApplication.shared.open(url)

//				for _ in 0 ... 30 {
//					if account.isConnected {
//						let client = try await Client.create(account: account, options: .init(api: .init(env: Constants.xmtpEnv)))
//						let keys = client.v1keys
//						try Keystore.saveKeys(address: client.address, keys: keys)
//
//						await MainActor.run {
//							withAnimation {
//								self.auth.status = .connected(client)
//							}
//						}
//						return
//					}
//
//					try await Task.sleep(for: .seconds(1))
//				}
//				await MainActor.run {
//					self.auth.status = .signedOut
//					self.errorViewModel.showError("Timed out waiting to connect (30 seconds)")
//				}
			} catch {
				await MainActor.run {
					self.auth.status = .signedOut
					self.errorViewModel.showError("Error connecting: \(error)")
				}
			}
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
						self.auth.status = .connected(client)
					}
				}
			} catch {
				await MainActor.run {
					self.auth.status = .signedOut
					self.errorViewModel.showError("Error generating random wallet: \(error)")
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
