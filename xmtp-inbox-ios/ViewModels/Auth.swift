//
//  Auth.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/25/23.
//

import Foundation
import SwiftUI
import XMTP

class Auth: ObservableObject {
	enum AuthStatus {
		case loadingKeys, signedOut, tryingDemo, connecting, connected(Client)
	}

	@Published var status: AuthStatus = .loadingKeys {
		didSet {
			Task {
				if case let .connected(client) = status {
					await MainActor.run {
						self.isShowingQRCode = false
					}

					do {
						try await DB.prepare(client: client)
					} catch {
						print("Error preparing DB: \(error)")
					}
				}
			}
		}
	}

	@Published var isShowingQRCode = false

	static func signOut(db: DB) {
		do {
			try Keystore.deleteKeys()
			try db.clear()
		} catch {
			print("Error signing out: \(error)")
		}
	}

	func signOut(db: DB) {
		Auth.signOut(db: db)
		withAnimation {
			self.status = .signedOut
		}
	}
}
