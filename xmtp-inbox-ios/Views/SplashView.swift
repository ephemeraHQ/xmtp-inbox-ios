//
//  SplashView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/21/22.
//

import SwiftUI

struct SplashView: View {
	var isConnecting: Bool
	var onTryDemo: () -> Void
	var onConnectWallet: (WalletProvider) -> Void

	@State private var isChoosingWallet = false
	@Binding var provider: WalletProvider?

	func connectWallet() {
		if let provider {
			onConnectWallet(provider)
		} else {
			isChoosingWallet.toggle()
		}
	}

	var body: some View {
		VStack {
			Image("XMTPGraphic")
				.resizable()
				.scaledToFit()

			Text("splash-title")
				.kerning(0.5)
				.font(.Display1)
				.multilineTextAlignment(.center)
				.padding(.bottom, 8)
				.padding(.horizontal)

			Text("splash-description")
				.font(.Body1)
				.multilineTextAlignment(.center)
				.padding(.bottom, 16)
				.padding(.horizontal)

			let buttonHeight = 58.0
			if isConnecting {
				Button(action: connectWallet) {
					ProgressView()
						.progressViewStyle(CircularProgressViewStyle(tint: .actionPrimaryText))
						.padding(4.0)
					Text("awaiting-signature")
						.kerning(0.5)
						.foregroundColor(.actionPrimaryText)
						.font(.H1)
				}
				.padding()
				.frame(maxWidth: .infinity, maxHeight: buttonHeight)
				.background(Color.actionPrimary)
				.clipShape(Capsule())
				.padding()
			} else {
				Button(action: connectWallet) {
					Text("connect-wallet-cta")
						.kerning(0.5)
						.padding()
						.frame(maxWidth: .infinity, maxHeight: buttonHeight)
						.background(Color.actionPrimary)
						.foregroundColor(.actionPrimaryText)
						.font(.H1)
						.clipShape(Capsule())
						.padding()
				}
			}
			Text("try-demo-cta")
				.kerning(0.5)
				.foregroundColor(.actionPrimary)
				.font(.Body1B)
				.onTapGesture {
					onTryDemo()
				}
		}
		.sheet(isPresented: $isChoosingWallet) {
			WalletSelectionSheet { provider in
				onConnectWallet(provider)
				self.provider = provider
			}
		}
	}
}

struct SplashView_Previews: PreviewProvider {
	static var onTryDemo: () -> Void = {}
	static var onConnectWallet: () -> Void = {}
	static var previews: some View {
		SplashView(isConnecting: false, onTryDemo: onTryDemo, onConnectWallet: { _ in
		}, provider: .constant(.rainbow))
	}
}
