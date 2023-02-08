//
//  WalletConnection.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation
import UIKit
import web3
import Web3Wallet
import Combine
import XMTP

enum WalletConnectionError: String, Error {
	case walletConnectURL
	case noSession
	case noAddress
	case invalidMessage
	case noSignature
}

protocol WalletConnection {
	var isConnected: Bool { get }
	var walletAddress: String? { get }
	func wcUrl() throws -> WalletConnectURI
	func connect() async throws
	func sign(_ data: Data) async throws -> Data
}

class WS: WalletConnectRelay.WebSocketConnecting {
	var webSocketTask: URLSessionWebSocketTask?

	var isConnected: Bool = false
	var onConnect: (() -> Void)?
	var onDisconnect: ((Error?) -> Void)?

	var overridingOnText = true
	var onText: ((String) -> Void)?
	var request: URLRequest

	init(request: URLRequest) {
		self.request = request
	}

	func connect() {
		let urlSession = URLSession(configuration: .default)
		webSocketTask = urlSession.webSocketTask(with: request)

		isConnected = true
		onConnect?()

		webSocketTask?.resume()
		receive()
	}

	func receive() {
		guard let webSocketTask else {
			return
		}

		webSocketTask.receive { result in
			switch result {
			case let .failure(error):
				print("WS receive failure: \(error)")
			case let .success(message):
				switch message {
				case let .string(text):
					print("Received text message: \(text)")
					self.onText?(text)
				case let .data(data):
					print("Received binary message: \(data)")
				@unknown default:
					print("Unkown message: \(message)")
				}
			}

			self.receive()
		}
	}

	func disconnect() {
		onDisconnect?(nil)
	}

	func write(string: String, completion: (() -> Void)?) {
		guard let webSocketTask else {
			return
		}

		webSocketTask.send(URLSessionWebSocketTask.Message.string(string)) { error in
			completion?()
		}
	}
}

struct WSFactory: WebSocketFactory {
	func create(with url: URL) -> WalletConnectRelay.WebSocketConnecting {
		let request = URLRequest(url: url)
		return WS(request: request)
	}
}

struct Signer: EthereumSigner {
	func sign(message: Data, with key: Data) throws -> EthereumSignature {
		let data = try KeyUtil.sign(message: message, with: key, hashing: false)
		return EthereumSignature(serialized: data)
	}

	func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
		let data = signature.serialized
		return try KeyUtil.recoverPublicKey(message: message, signature: data)
	}

	func keccak256(_ data: Data) -> Data {
		data.web3.keccak256
	}
}

struct XMTPSignerFactory: SignerFactory {
	func createEthereumSigner() -> EthereumSigner {
		Signer()
	}
}

class WCWalletConnection: WalletConnection {
	static private var publishers = [AnyCancellable]()
	static func configure() {
		let metadata = AppMetadata(name: "XMTP Inbox", description: "", url: "https://xmtp.org", icons: [])
		Networking.configure(projectId: Constants.walletConnectKey, socketFactory: WSFactory())
		Web3Wallet.configure(metadata: metadata, signerFactory: XMTPSignerFactory())
		Pair.configure(metadata: metadata)
		Web3Wallet.instance.sessionProposalPublisher.sink { proposal in
			print("got a proposal \(proposal)")
		}.store(in: &publishers)
	}
	var isConnected: Bool = false
	var walletAddress: String?

	func wcUrl() throws -> WalletConnectURI {
		WalletConnectURI(topic: "hi", symKey: "hi", relay: .init(protocol: "irn", data: nil))
	}

	func connect() async throws {
		
	}

	func sign(_: Data) async throws -> Data {
		Data("hi".utf8)
	}
}
