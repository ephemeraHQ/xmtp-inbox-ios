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

	@Published var status: AuthStatus = .loadingKeys
	@Published var isShowingQRCode = false

	func signOut() {
		do {
			try Keystore.deleteKeys()
			withAnimation {
				self.status = .signedOut
			}
		} catch {
			print("Error signing out: \(error.localizedDescription)")
		}
	}
}
