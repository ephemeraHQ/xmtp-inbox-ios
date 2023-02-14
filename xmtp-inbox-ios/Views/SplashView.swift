//
//  SplashView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/21/22.
//

import SwiftUI
import WebKit

class FullScreenWKWebView: WKWebView {
		override var safeAreaInsets: UIEdgeInsets {
				return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		}
}

struct WalletConnectionWebview: UIViewRepresentable {
	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
		var webView: FullScreenWKWebView

		override init() {
			let configuration = WKWebViewConfiguration()
			webView = FullScreenWKWebView(frame: .zero, configuration: configuration)

			super.init()

			webView.uiDelegate = self
			webView.navigationDelegate = self

			// swiftlint:disable no_optional_try
			guard let connectHTMLURL = Bundle.main.url(forResource: "connect", withExtension: "html"),
						let connectHTMLData = try? Data(contentsOf: connectHTMLURL) else {
				fatalError("no content")
			}
			// swiftlint:disable no_optional_try

			let request = URLRequest(url: connectHTMLURL)
			webView.load(request)
		}

		func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
			if let navigation {
				print("did start provisional navigation: \(webView.url)")
			}
		}
	}

	func makeUIView(context: Context) -> FullScreenWKWebView {
		context.coordinator.webView
	}

	func updateUIView(_ uiView: FullScreenWKWebView, context: Context) {

	}
}

struct SplashView: View {
	var isConnecting: Bool
	var onTryDemo: () -> Void
	var onConnectWallet: () -> Void
	@State private var isShowingWebview = true

	var body: some View {
		WalletConnectionWebview()
			.ignoresSafeArea(.all)
//		VStack {
//			Image("XMTPGraphic")
//				.resizable()
//				.scaledToFit()
//
//			Text("splash-title")
//				.kerning(0.5)
//				.font(.Display1)
//				.multilineTextAlignment(.center)
//				.padding(.bottom, 8)
//				.padding(.horizontal)
//
//			Text("splash-description")
//				.font(.Body1)
//				.multilineTextAlignment(.center)
//				.padding(.bottom, 16)
//				.padding(.horizontal)
//
//			let buttonHeight = 58.0
//			if isConnecting {
//				Button(action: onConnectWallet) {
//					ProgressView()
//						.progressViewStyle(CircularProgressViewStyle(tint: .actionPrimaryText))
//						.padding(4.0)
//					Text("awaiting-signature")
//						.kerning(0.5)
//						.foregroundColor(.actionPrimaryText)
//						.font(.H1)
//				}
//				.padding()
//				.frame(maxWidth: .infinity, maxHeight: buttonHeight)
//				.background(Color.actionPrimary)
//				.clipShape(Capsule())
//				.padding()
//			} else {
//				Button(action: onConnectWallet) {
//					Text("connect-wallet-cta")
//						.kerning(0.5)
//						.padding()
//						.frame(maxWidth: .infinity, maxHeight: buttonHeight)
//						.background(Color.actionPrimary)
//						.foregroundColor(.actionPrimaryText)
//						.font(.H1)
//						.clipShape(Capsule())
//						.padding()
//				}
//			}
//			Text("try-demo-cta")
//				.kerning(0.5)
//				.foregroundColor(.actionPrimary)
//				.font(.Body1B)
//				.onTapGesture {
//					onTryDemo()
//				}
//		}
//		.sheet(isPresented: $isShowingWebview) {
//			WalletConnectionWebview()
//				.presentationDetents([.medium])
//		}
	}
}

struct SplashView_Previews: PreviewProvider {
	static var onTryDemo: () -> Void = {}
	static var onConnectWallet: () -> Void = {}
	static var previews: some View {
		SplashView(isConnecting: false, onTryDemo: onTryDemo, onConnectWallet: onConnectWallet)
			.ignoresSafeArea()
	}
}
