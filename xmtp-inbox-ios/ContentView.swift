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

	@State private var wcUrl: URL?

	@StateObject private var errorViewModel = ErrorViewModel()

	var body: some View {
		ZStack {
			Color.backgroundPrimary.edgesIgnoringSafeArea(.all)
			switch environmentCoordinator.auth.status {
			case let .connected(client):
				HomeView(client: client)
			case .connecting:
				ProgressView("Awaiting signatures…")
			case .loadingKeys:
				ProgressView()
			default:
				SplashView(onTryDemo: onTryDemo, onConnecting: onConnecting, onConnected: onConnectWallet)
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

	func onConnecting() {
		withAnimation {
			environmentCoordinator.auth.status = .connecting
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

	func onConnectWallet(client: Client) {
		do {
			let keys = client.v1keys
			try Keystore.saveKeys(address: client.address, keys: keys)
		} catch {
			print("Error saving keys: \(error)")
		}

		withAnimation {
			environmentCoordinator.auth.status = .connected(client)
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
