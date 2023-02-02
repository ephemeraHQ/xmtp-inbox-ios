//
//  xmtp_inbox_iosApp.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import SwiftUI

@main
struct xmtp_inbox_iosApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
				.onAppear {
					do {
						try DB.shared.prepare(passphrase: "make this real")
					} catch {
						print("Error preparing DB: \(error)")
					}
				}
		}
	}
}
