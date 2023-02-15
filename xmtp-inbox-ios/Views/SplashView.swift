//
//  SplashView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/21/22.
//

import SwiftUI
import WebKit
import XMTP

class FullScreenWKWebView: WKWebView {
	override var safeAreaInsets: UIEdgeInsets {
		return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
	}
}

struct WebviewSignerRequest: Codable {
	var nonce: String
	var content: String
}

class WebviewSigner: NSObject, SigningKey {
	enum WebviewSignerError: Error {
		case requestInProgress, invalidSignatureData
	}

	var webView: WKWebView
	var address: String
	var continuation: CheckedContinuation<Signature, Error>?

	init(webView: WKWebView, address: String) {
		self.webView = webView
		self.address = address
	}

	func handle(_ message: WKScriptMessage) {
		print("signer got a message: \(message.body)")
		if let dict = message.body as? NSDictionary,
		   let signature = dict["signature"] as? String,
		   let signatureData = Data(base64Encoded: Data(signature.utf8))
		{
			if signatureData.count != 65 {
				let continuation = self.continuation
				self.continuation = nil
				continuation?.resume(throwing: WebviewSignerError.invalidSignatureData)
				return
			}

			do {
				let signature = XMTP.Signature.with {
					$0.ecdsaCompact.bytes = signatureData[0 ..< 64]
					$0.ecdsaCompact.recovery = UInt32(signatureData[64])
				}

				let continuation = self.continuation
				self.continuation = nil
				continuation?.resume(returning: signature)
			} catch {
				let continuation = self.continuation
				self.continuation = nil
				continuation?.resume(throwing: error)
			}
		}
	}

	// MARK: SigningKey conformance

	func sign(_ data: Data) async throws -> XMTP.Signature {
		if let continuation {
			continuation.resume(throwing: WebviewSignerError.requestInProgress)
			self.continuation = nil
		}

		let nonce = UUID().uuidString
		let base64Content = data.base64EncodedString()
		let request = WebviewSignerRequest(nonce: nonce, content: base64Content)
		guard let requestJSON = String(data: try JSONEncoder().encode(request), encoding: .utf8) else {
			throw WebviewSignerError.invalidSignatureData
		}

		print("DATA sign(\(requestJSON))")
		await MainActor.run {
			webView.evaluateJavaScript("sign(\(requestJSON))") { a, b in
				print("a: \(a)")
				print("b: \(b)")
			}
		}

		return try await withCheckedThrowingContinuation { continuation in
			self.continuation = continuation
		}
	}

	func sign(message: String) async throws -> XMTP.Signature {
		return try await sign(Data(message.utf8))
	}
}

struct WalletConnectionWebview: UIViewRepresentable {
	var onTryDemo: () -> Void
	var onConnecting: () -> Void
	var onConnected: (Client) -> Void

	func makeCoordinator() -> Coordinator {
		Coordinator(onTryDemo: onTryDemo, onConnecting: onConnecting, onConnected: onConnected)
	}

	class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
		var onTryDemo: () -> Void
		var onConnecting: () -> Void
		var onConnected: (Client) -> Void

		var webView: FullScreenWKWebView!
		var signer: WebviewSigner?

		init(onTryDemo: @escaping () -> Void, onConnecting: @escaping () -> Void, onConnected: @escaping (Client) -> Void) {
			self.onTryDemo = onTryDemo
			self.onConnecting = onConnecting
			self.onConnected = onConnected

			super.init()

			// Clear cache
			WKWebsiteDataStore.default().removeData(
				ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
				modifiedSince: Date(timeIntervalSince1970: 0)
			) {}

			let contentController = WKUserContentController()
			contentController.add(self, name: "signer")

			let configuration = WKWebViewConfiguration()
			configuration.userContentController = contentController

			webView = FullScreenWKWebView(frame: .zero, configuration: configuration)
			webView.uiDelegate = self
			webView.navigationDelegate = self

			guard let connectHTMLURL = Bundle.main.url(forResource: "connect", withExtension: "html") else {
				fatalError("no content")
			}

			let request = URLRequest(url: connectHTMLURL)
			webView.load(request)
		}

		func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
			guard let dict = message.body as? NSDictionary else {
				print("No dict from message: \(message)")
				return
			}

			if let address = dict["address"] as? String {
				onConnecting()

				let signer = WebviewSigner(webView: webView, address: address)
				self.signer = signer

				Task {
					let client = try await Client.create(account: signer, options: .init(api: .init(env: Constants.xmtpEnv)))
					await MainActor.run {
						self.onConnected(client)
					}
				}
			} else if let demoMode = dict["demoMode"] as? String, demoMode == "true" {
				onTryDemo()
			} else {
				signer?.handle(message)
			}
		}

		func webView(_: WKWebView, decidePolicyFor _: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
			decisionHandler(.allow)
		}
	}

	func makeUIView(context: Context) -> FullScreenWKWebView {
		context.coordinator.webView
	}

	func updateUIView(_: FullScreenWKWebView, context _: Context) {}
}

struct SplashView: View {
	var onTryDemo: () -> Void
	var onConnecting: () -> Void
	var onConnected: (Client) -> Void
	@State private var isShowingWebview = true

	var body: some View {
		WalletConnectionWebview(onTryDemo: onTryDemo, onConnecting: onConnecting, onConnected: onConnected)
			.ignoresSafeArea(.all)
	}
}

struct SplashView_Previews: PreviewProvider {
	static var onTryDemo: () -> Void = {}
	static var onConnectWallet: (Client) -> Void = { _ in }
	static var previews: some View {
		SplashView(onTryDemo: onTryDemo, onConnecting: {}, onConnected: onConnectWallet)
			.ignoresSafeArea()
	}
}
