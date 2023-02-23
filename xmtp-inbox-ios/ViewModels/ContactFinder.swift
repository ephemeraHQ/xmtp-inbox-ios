//
//  ContactFinder.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/17/23.
//

import Combine
import Foundation
import SwiftUI
import XMTP

struct ContactFinderResult: Identifiable {
	var id: String { address }
	var address: String
	var ens: String?
}

class ContactFinder: ObservableObject {
	var client: XMTP.Client
	var cancellables: [AnyCancellable] = []
	var validateTask: Task<Void, Never>?

	@Published var searchText: String = ""
	@Published var results: [ContactFinderResult] = []
	@Published var error: String?

	init(client: XMTP.Client) {
		self.client = client

		$searchText.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main).sink { [weak self] _ in
			self?.validate()
		}.store(in: &cancellables)
	}

	deinit {
		for cancelleable in cancellables {
			cancelleable.cancel()
		}
	}

	func validate() {
		validateTask?.cancel()
		validateTask = Task {
			do {
				if searchText.hasSuffix(".eth") {
					if let address = try await lookupENS() {
						try await validateAddress(address: address, ens: searchText)
					} else {
						await setError("No address found for \(searchText)")
					}
				} else {
					try await validateAddress(address: searchText, ens: nil)
				}
			} catch {
				print("Error searching: \(error)")
			}
		}
	}

	func setError(_ message: String) async {
		await MainActor.run {
			withAnimation {
				self.results = []
				self.error = message
			}
		}
	}

	func lookupENS() async throws -> String? {
		return await ENS.shared.address(ens: searchText)
	}

	func validateAddress(address: String, ens: String?) async throws {
		await MainActor.run {
			self.results = []
			self.error = nil
		}

		let range = NSRange(location: 0, length: address.utf16.count)
		let regex = try NSRegularExpression(pattern: "^0x[a-fA-F0-9]{40}$")
		if regex.firstMatch(in: address, options: [], range: range) != nil {
			await MainActor.run {
				results = [
					ContactFinderResult(address: address, ens: ens),
				]
			}
		} else {
			if !address.isEmpty {
				await setError(NSLocalizedString("invalid-ethereum-address", comment: ""))
			}
		}

		if address.lowercased() == client.address.lowercased() {
			await setError(NSLocalizedString("cannot-message-self", comment: ""))
		}
	}
}
