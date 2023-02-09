//
//  xmtp_inbox_iosApp.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 12/20/22.
//

import SwiftUI

@main
struct xmtp_inbox_iosApp: App {
	@AppStorage("dbVersion") var dbVersion: Int = 0

	var body: some Scene {
		WindowGroup {
			ContentView()
				.onAppear {
					do {
						try DB.shared.prepare(passphrase: "make this real", reset: dbVersion != DB.version)
						self.dbVersion = DB.version
					} catch {
						print("Error preparing DB: \(error)")
					}
				}
		}
	}
}
