//
//  Account.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//
import Foundation
import UIKit
import XMTP
import WalletConnectSwift

public enum WalletProvider {
	case rainbow, metamask, walletconnect

	func url(from account: Account) -> URL {
		let topic = account.connection.topic
		let bridgeURL = account.connection.bridge
		let key = account.connection.key

		return URL(forceString: "wc:\(topic)@1?bridge=\(bridgeURL)&key=\(key)")
	}

	func openableURL(from account: Account) -> URL {
		let topic = account.connection.topic
		let bridgeURL = account.connection.bridge
		let key = account.connection.key

		switch self {
		case .rainbow:
			let url = "wc:\(topic)@1?bridge=\(bridgeURL)&key=\(key)"
			let escaped = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)?
				.replacing("&", with: "%26")
				.replacing("=", with: "%3D")
			// swiftlint:disable force_unwrapping
			return URL(forceString: "https://rnbwapp.com/wc?uri=\(escaped!)")
			// swiftlint:enable force_unwrapping
		case .metamask:
			return URL(forceString: "metamask://wc")
		case .walletconnect:
			let wcURL = WCURL(topic: topic.uuidString, bridgeURL: URL(forceString: bridgeURL), key: key)
			return URL(forceString: "wc://wc?uri=\(wcURL.absoluteString)")
		}
	}
}

/// Wrapper around a WalletConnect V1 wallet connection. Account conforms to ``SigningKey`` so
/// you can use it to create a ``Client``.
///
/// > Warning: The WalletConnect V1 API will be deprecated soon.
public struct Account: Sendable {
	var connection: WCWalletConnection

	public static func create() throws -> Account {
		let connection = WCWalletConnection()
		return try Account(connection: connection)
	}

	init(connection: WCWalletConnection) throws {
		self.connection = connection
	}

	public var isConnected: Bool {
		connection.isConnected
	}

	public var address: String {
		connection.walletAddress ?? ""
	}

	public func connect() async throws {
		try await connection.connect()
	}
}

extension Account: SigningKey {
	public func sign(_ data: Data) async throws -> Signature {
		let signatureData = try await connection.sign(data)

		var signature = Signature()

		signature.ecdsaCompact.bytes = signatureData[0 ..< 64]
		signature.ecdsaCompact.recovery = UInt32(signatureData[64])

		return signature
	}

	public func sign(message: String) async throws -> Signature {
		return try await sign(Data(message.utf8))
	}
}
