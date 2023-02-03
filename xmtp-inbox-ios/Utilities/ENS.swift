//
//  ENS.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import Foundation
import web3

// Manages ENS lookups
class ENS: ObservableObject {
	static let shared = ENS()

	var observed: [String: String?] = [:]
	var service: EthereumNameService?

	init() {
		if let infuraURL = Constants.infuraUrl {
			let ethClient = EthereumHttpClient(url: infuraURL, network: .mainnet)
			service = EthereumNameService(client: ethClient)
		}
	}

	func ens(address: String) async -> String? {
		guard let service else {
			return nil
		}

		do {
			let results = try await service.resolve(addresses: [EthereumAddress(address)])

			guard let result = results.first, case let .resolved(value) = result.output else {
				return nil
			}

			return value
		} catch {
			return nil
		}
	}
}
