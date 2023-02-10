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

	func ens(addresses: [String]) async throws -> [String: String?] {
		var addressesWithENS = [String: String?]()

		guard let service else {
			return addressesWithENS
		}

		let results = try await service.resolve(addresses: addresses.map { EthereumAddress($0) })
		for result in results {
			if case let .resolved(value) = result.output {
				addressesWithENS[result.address.value.lowercased()] = value
			}
		}

		return addressesWithENS
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
