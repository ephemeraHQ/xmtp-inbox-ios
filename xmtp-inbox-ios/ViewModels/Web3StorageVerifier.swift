//
//  Web3Storage.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/27/23.
//

import Foundation
import SwiftUI

class Web3StorageVerifier: ObservableObject {
	enum Status: Equatable {
		case waiting, verifying, verified, error(String)
	}

	static var loginURL: URL {
		if let url = URL(string: "https://web3.storage/login/") {
			return url
		}

		fatalError("Could not get URL for login")
	}

	@Published var status: Status = .waiting
	@Published var token: String = ""

	init() {
		if let token = AppGroup.keychain[Web3Storage.keychainKey] {
			self.token = token
			status = .verified
		}
	}

	func verify() async {
		guard let url = URL(string: "https://api.web3.storage/user/uploads") else {
			await MainActor.run {
				withAnimation {
					self.status = .error("Could not get valid URL for web3.storage API")
				}
			}

			return
		}

		var request = URLRequest(url: url)
		request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		do {
			let (data, response) = try await URLSession.shared.data(for: request)

			guard let response = response as? HTTPURLResponse else {
				await MainActor.run {
					withAnimation {
						self.status = .error("Invalid response from web3.storage API")
					}
				}

				return
			}

			await MainActor.run {
				withAnimation {
					if response.statusCode == 200 {
						self.status = .verified
					} else {
						self.status = .error("Token does not seem to be valid: \(response.statusCode).")
					}
				}
			}
		} catch {
			await MainActor.run {
				withAnimation {
					self.status = .error(error.localizedDescription)
				}
			}
		}
	}
}
