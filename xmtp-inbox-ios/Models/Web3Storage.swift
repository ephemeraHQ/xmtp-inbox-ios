//
//  Web3Storage.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/27/23.
//

import Foundation

enum Web3StorageError: Error {
	case invalidURL, noToken
}

struct Web3Storage: Uploader {
	struct Response: Codable {
		var cid: String
	}

	static let keychainKey = "appStorageKey"

	var token: String?

	init() {
		token = AppGroup.keychain[Web3Storage.keychainKey]
	}

	mutating func ensureToken() {
		if token == nil {
			token = AppGroup.keychain[Web3Storage.keychainKey]
		}
	}

	func upload(data: Data) async throws -> String {
		guard let url = URL(string: "https://api.web3.storage/upload") else {
			throw Web3StorageError.invalidURL
		}

		var token: String? = self.token

		if token == nil {
			token = AppGroup.keychain[Web3Storage.keychainKey]
		}

		guard let token else {
			throw Web3StorageError.noToken
		}

		var request = URLRequest(url: url)
		request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.addValue("XMTP", forHTTPHeaderField: "X-NAME")
		request.httpMethod = "POST"

		let responseData = try await URLSession.shared.upload(for: request, from: data).0
		let response = try JSONDecoder().decode(Web3Storage.Response.self, from: responseData)

		return "https://\(response.cid).ipfs.w3s.link"
	}
}
