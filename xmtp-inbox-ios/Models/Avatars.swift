//
//  Avatars.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/17/23.
//

import ENSKit
import Foundation
import IGIdenticon
import UIKit
import web3

enum EnsError: Error {
	case invalidURL
}

class Avatars {
	static let shared = Avatars()

	// It's a singleton
	private init() {}

	var ensKit: ENSKit?
	var ethClient: EthereumHttpClient?

	let avatarCacheDirectory = URL.documentsDirectory.appending(path: "cache/avatars")

	func cachedAvatarFor(address: String, size: CGFloat) -> UIImage? {
		do {
			let cachedURL = cachedURL(address: address, size: size)

			if !FileManager.default.fileExists(atPath: cachedURL.path) {
				return nil
			}

			let data = try Data(contentsOf: cachedURL)
			let uiImage = UIImage(data: data)

			return uiImage
		} catch {
			print("Error reading cached avatar: \(error)")
		}

		return nil
	}

	func loadAvatarFor(address: String, size: CGFloat) async -> UIImage? {
		if let uiImage = (await loadEnsImage(address: address) ?? Identicon().icon(from: address, size: CGSize(width: size, height: size))) {
			cache(uiImage, for: address, size: size)

			return uiImage
		}

		return nil
	}

	func cache(_ uiImage: UIImage, for address: String, size: CGFloat) {
		do {
			// swiftlint:disable no_optional_try
			try? FileManager.default.createDirectory(at: avatarCacheDirectory, withIntermediateDirectories: true)
			// swiftlint:enable no_optional_try

			let cachedURL = cachedURL(address: address, size: size)
			try uiImage.pngData()?.write(to: cachedURL)
		} catch {
			print("Error caching avatar for \(address): \(error)")
		}
	}

	private func cachedURL(address: String, size: CGFloat) -> URL {
		let key = "\(address)-\(size)x\(size)"
		return avatarCacheDirectory.appending(path: key)
	}

	func loadEnsImage(address: String) async -> UIImage? {
		do {
			guard let ensName = await ENS.shared.ens(address: address) else {
				return nil
			}

			let ensKit = try setupEnsKit()
			let avatar = await ensKit.avatar(name: ensName)

			guard let imageData = avatar else {
				return nil
			}

			return UIImage(data: imageData)
		} catch {
			print("Error resolving ENS avatar: \(error)")
		}

		return nil
	}

	func setupEthClient() throws -> EthereumHttpClient {
		guard let ethClient = ethClient else {
			guard let infuraUrl = Constants.infuraUrl else {
				throw EnsError.invalidURL
			}
			let newEthClient = EthereumHttpClient(url: infuraUrl, network: .mainnet)
			self.ethClient = newEthClient
			return newEthClient
		}
		return ethClient
	}

	func setupEnsKit() throws -> ENSKit {
		guard let ensKit = ensKit else {
			guard let infuraUrl = Constants.infuraUrl else {
				throw EnsError.invalidURL
			}
			let newEnsKit = ENSKit(jsonrpcClient: InfuraEthereumAPI(url: infuraUrl))
			self.ensKit = newEnsKit
			return newEnsKit
		}
		return ensKit
	}
}
