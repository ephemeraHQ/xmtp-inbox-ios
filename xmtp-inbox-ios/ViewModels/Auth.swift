//
//  Auth.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/25/23.
//

import Foundation
import SwiftUI
import XMTP

struct Auth {
	enum AuthStatus {
		case loadingKeys, signedOut, tryingDemo, connecting, connected(Client)
	}

	var status: AuthStatus = .loadingKeys {
		didSet {
			if case let .connected(client) = status {
				self.isShowingQRCode = false

				do {
					try DB.prepare(client: client)
				} catch {
					print("Error preparing DB: \(error)")
				}
			}
		}
	}

	var isShowingQRCode = false

	static func signOut() {
		do {
			try Keystore.deleteKeys()
			try DB.clear()
		} catch {
			print("Error signing out: \(error)")
		}
	}

	mutating func signOut() {
		Auth.signOut()
		withAnimation {
			self.status = .signedOut
		}
	}
}
