//
//  WalletConnection.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation
import UIKit
import WalletConnectSwift
import web3
import XMTP

enum WalletConnectionError: String, Error {
	case walletConnectURL
	case noSession
	case noAddress
	case invalidMessage
	case noSignature
}

class WCWalletConnection: WalletConnectSwift.ClientDelegate {
	@Published public var isConnected = false

	var walletConnectClient: WalletConnectSwift.Client!
	var session: WalletConnectSwift.Session? {
		didSet {
			DispatchQueue.main.async {
				self.isConnected = self.session != nil
			}
		}
	}

	var topic: UUID
	var key: String
	var bridge = "https://bridge.walletconnect.org"

	init() {
		// swiftlint:disable force_try
		let keybytes = try! WCWalletConnection.secureRandomBytes(count: 32)
		// swiftlint:enable force_try
		key = keybytes.reduce("") { $0 + String(format: "%02x", $1) }
		topic = UUID()

		let peerMeta = Session.ClientMeta(
			name: "XMTP Inbox",
			description: "Universal XMTP messaging app",
			icons: [],
			// swiftlint:disable force_unwrapping
			url: URL(string: "https://xmtp.org")!
			// swiftlint:enable force_unwrapping
		)
		let dAppInfo = WalletConnectSwift.Session.DAppInfo(peerId: UUID().uuidString, peerMeta: peerMeta)

		walletConnectClient = WalletConnectSwift.Client(delegate: self, dAppInfo: dAppInfo)
	}

	lazy var walletConnectURL: WCURL = {
		// swiftlint:disable force_unwrapping
		WCURL(topic: topic.uuidString, bridgeURL: URL(string: bridge)!, key: key)
		// swiftlint:enable force_unwrapping
	}()

	static func secureRandomBytes(count: Int) throws -> Data {
		var bytes = [UInt8](repeating: 0, count: count)

		// Fill bytes with secure random data
		let status = SecRandomCopyBytes(
			kSecRandomDefault,
			count,
			&bytes
		)

		// A status of errSecSuccess indicates success
		if status == errSecSuccess {
			return Data(bytes)
		} else {
			fatalError("could not generate random bytes")
		}
	}

	func connect() async throws {
		try walletConnectClient.connect(to: walletConnectURL)
	}

	func sign(_ data: Data) async throws -> Data {
		guard session != nil else {
			throw WalletConnectionError.noSession
		}

		guard let walletAddress = walletAddress else {
			throw WalletConnectionError.noAddress
		}

		guard let message = String(data: data, encoding: .utf8) else {
			throw WalletConnectionError.invalidMessage
		}

		return try await withCheckedThrowingContinuation { continuation in
			do {
				try walletConnectClient.personal_sign(url: walletConnectURL, message: message, account: walletAddress) { response in
					if let error = response.error {
						continuation.resume(throwing: error)
						return
					}

					do {
						var resultString = try response.result(as: String.self)

						// Strip leading 0x that we get back from `personal_sign`
						if resultString.hasPrefix("0x"), resultString.count == 132 {
							resultString = String(resultString.dropFirst(2))
						}

						guard let resultDataBytes = resultString.web3.bytesFromHex else {
							continuation.resume(throwing: WalletConnectionError.noSignature)
							return
						}

						var resultData = Data(resultDataBytes)

						// Ensure we have a valid recovery byte
						resultData[resultData.count - 1] = 1 - resultData[resultData.count - 1] % 2

						continuation.resume(returning: resultData)
					} catch {
						continuation.resume(throwing: error)
					}
				}
			} catch {
				continuation.resume(throwing: error)
			}
		}
	}

	var walletAddress: String? {
		if let address = session?.walletInfo?.accounts.first {
			return EthereumAddress(address).toChecksumAddress()
		}

		return nil
	}

	func client(_: WalletConnectSwift.Client, didConnect _: WalletConnectSwift.WCURL) {}

	func client(_: WalletConnectSwift.Client, didFailToConnect _: WalletConnectSwift.WCURL) {}

	func client(_: WalletConnectSwift.Client, didConnect session: WalletConnectSwift.Session) {
		// TODO: Cache session
		self.session = session
	}

	func client(_: WalletConnectSwift.Client, didUpdate session: WalletConnectSwift.Session) {
		self.session = session
	}

	func client(_: WalletConnectSwift.Client, didDisconnect _: WalletConnectSwift.Session) {
		session = nil
	}
}
