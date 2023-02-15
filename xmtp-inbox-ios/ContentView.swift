//
//  ContentView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import AlertToast
import SwiftUI
import XMTP

struct ContentView: View {
	@StateObject private var environmentCoordinator = EnvironmentCoordinator()

	// TODO: Move all this elsewhere
	@State private var wcUrl: URL?
	@State private var provider: WalletProvider?

	@StateObject private var errorViewModel = ErrorViewModel()

	var body: some View {
		ZStack {
			Color.backgroundPrimary.edgesIgnoringSafeArea(.all)

			switch environmentCoordinator.auth.status {
			case .loadingKeys:
				ProgressView()
			case .signedOut, .tryingDemo:
				SplashView(isConnecting: false, onTryDemo: onTryDemo, onConnectWallet: onConnectWallet, provider: $provider)
			case .connecting:
				SplashView(isConnecting: true, onTryDemo: onTryDemo, onConnectWallet: onConnectWallet, provider: $provider)
			case let .connected(client):
				HomeView(client: client)
			}
		}
		.toast(isPresenting: $errorViewModel.isShowing) {
			AlertToast.error(errorViewModel.errorMessage)
		}
		.sheet(isPresented: $environmentCoordinator.auth.isShowingQRCode) {
			if let wcUrl {
				QRCodeView(data: Data(wcUrl.absoluteString.utf8))
			} else {
				Text("Cannot connect to wallet.")
			}
		}
		.environmentObject(environmentCoordinator)
		.task {
			await loadClient()
		}
	}

	func loadClient() async {
		do {
			guard let keys = try Keystore.readKeys() else {
				await MainActor.run {
					environmentCoordinator.auth.status = .signedOut
				}
				return
			}
			let client = try Client.from(v1Bundle: keys, options: .init(api: .init(env: Constants.xmtpEnv)))
			await MainActor.run {
				environmentCoordinator.auth.status = .connected(client)
			}
		} catch {
			print("Keystore read error: \(error.localizedDescription)")
			await MainActor.run {
				environmentCoordinator.auth.status = .signedOut
			}
		}
	}

	func onConnectWallet(provider: WalletProvider) {
		UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

		// If already connecting, bounce back out to the WalletConnect URL
		if case .connecting = environmentCoordinator.auth.status {
			// swiftlint:disable force_unwrapping
			if self.wcUrl != nil && UIApplication.shared.canOpenURL(wcUrl!) {
				let openableURL = URL(string: "\(provider.scheme)/wc?uri=\(wcUrl!.absoluteString)")
				UIApplication.shared.open(openableURL!, options: [.universalLinksOnly: true])
				return
			}
			// swiftlint:enable force_unwrapping
		}

		environmentCoordinator.auth.status = .connecting

		Task.detached {
			do {
				let account = try Account.create()

				let url = "wc:\(account.connection.topic)@1?bridge=\(account.connection.bridge)&key=\(account.connection.key)"
				let escaped = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)?
					.replacing("&", with: "%26")
					.replacing("=", with: "%3D")
				guard let escaped,
				      let openableURL = URL(string: "\(provider.scheme)/wc?uri=\(escaped)")
				else {
					return
				}

				print("openable url: \(openableURL.absoluteString)")

				await MainActor.run {
					self.wcUrl = URL(string: url)
					environmentCoordinator.auth.isShowingQRCode = !UIApplication.shared.canOpenURL(openableURL)
				}

				await MainActor.run {
					do {
						UIApplication.shared.open(openableURL, options: [.universalLinksOnly: true])
					} catch {
						environmentCoordinator.auth.isShowingQRCode = true
					}
				}

				try await account.connect()
				for _ in 0 ... 30 {
					if account.isConnected {
						let client = try await Client.create(account: account, options: .init(api: .init(env: Constants.xmtpEnv)))
						let keys = client.v1keys
						try Keystore.saveKeys(address: client.address, keys: keys)

						await MainActor.run {
							withAnimation {
								environmentCoordinator.auth.status = .connected(client)
							}
						}
						return
					}

					try await Task.sleep(for: .seconds(1))
				}
				await MainActor.run {
					environmentCoordinator.auth.status = .signedOut
					self.errorViewModel.showError("Timed out waiting to connect (30 seconds)")
				}
			} catch {
				await MainActor.run {
					environmentCoordinator.auth.status = .signedOut
					self.errorViewModel.showError("Error connecting: \(error)")
				}
			}
		}
	}

	func onTryDemo() {
		UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
		environmentCoordinator.auth.status = .tryingDemo
		Task {
			do {
				let account = try PrivateKey.generate()
				let client = try await Client.create(account: account, options: .init(api: .init(env: Constants.xmtpEnv)))
				let keys = client.v1keys
				try Keystore.saveKeys(address: client.address, keys: keys)

				await MainActor.run {
					withAnimation {
						environmentCoordinator.auth.status = .connected(client)
					}
				}
			} catch {
				await MainActor.run {
					environmentCoordinator.auth.status = .signedOut
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
