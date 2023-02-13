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
			if case .connected = status {
				self.isShowingQRCode = false
			}
		}
	}

	var isShowingQRCode = false

	static func signOut() {
		do {
			try Keystore.deleteKeys()
			try DB.shared.clear()
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
