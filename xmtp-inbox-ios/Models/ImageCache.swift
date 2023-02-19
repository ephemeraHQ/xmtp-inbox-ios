//
//  ImageCache.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/18/23.
//

import CryptoKit
import Foundation
import SwiftUI
import UIKit

// swiftlint:disable no_optional_try
struct ImageCache {
	static let shared = ImageCache()

	private init() {}

	func save(url: URL) async throws {
		try? FileManager.default.createDirectory(at: imageCacheURL, withIntermediateDirectories: true)

		let (data, _) = try await URLSession.shared.data(from: url)
		try data.write(to: cacheKey(for: url))
	}

	func load(url: URL?) -> Image? {
		try? FileManager.default.createDirectory(at: imageCacheURL, withIntermediateDirectories: true)

		guard let url else {
			return nil
		}

		do {
			let data = try Data(contentsOf: cacheKey(for: url))
			if let uiImage = UIImage(data: data) {
				return Image(uiImage: uiImage)
			}

			return nil
		} catch {
			return nil
		}
	}

	var imageCacheURL: URL {
		URL.documentsDirectory.appendingPathComponent("cache/images")
	}

	private func cacheKey(for url: URL) -> URL {
		let hashed = SHA256.hash(data: url.dataRepresentation).description
		return imageCacheURL.appendingPathComponent(hashed)
	}
}
