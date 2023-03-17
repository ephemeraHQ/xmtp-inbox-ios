//
//  DebugView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/13/23.
//

import SwiftUI
import XMTP

struct EnvironmentToggleView: View {
	@EnvironmentObject var environmentCoordinator: EnvironmentCoordinator
	@EnvironmentObject var auth: Auth

	@Environment(\.dismiss) var dismiss
	@Environment(\.db) var db

	var body: some View {
		HStack {
			Text(label)
			Spacer()
			Button(action: {
				toggle(db: db)
			}) {
				Text("Switch to \(other)")
			}
		}
	}

	func toggle(db: DB) {
		if XMTPEnvironmentManager.shared.environment == .production {
			XMTPEnvironmentManager.shared.environment = .dev
		} else {
			XMTPEnvironmentManager.shared.environment = .production
		}

		Task {
			await auth.signOut(db: db)
		}

		dismiss()
	}

	var label: String {
		if XMTPEnvironmentManager.shared.environment == .production {
			return "Production"
		} else {
			return "Dev"
		}
	}

	var other: String {
		if XMTPEnvironmentManager.shared.environment == .production {
			return "Dev"
		} else {
			return "Production"
		}
	}
}

struct DebugView: View {
	@Environment(\.db) var db
	
	var body: some View {
		NavigationStack {
			List {
				Section("Local Storage") {
					NavigationLink(destination: SQLDebuggerView()) {
						Text("SQL Debugger")
					}
					Button("Clear DB") {
						do {
							Task {
								try await db.clear()
							}
						} catch {
							Flash.add(.error("Error clearing the DB: \(error)"))
						}
					}
				}

				Section("XMTP Environment") {
					EnvironmentToggleView()
				}

				Section("Request Push Notification Access") {
					Button("Request") {
						Task {
							try? await XMTPPush.shared.request()
						}
					}
				}
			}
			.navigationTitle("Debug")
			.navigationBarTitleDisplayMode(.inline)
		}
		.scrollContentBackground(.visible)
	}
}

struct DebugView_Previews: PreviewProvider {
	static var previews: some View {
		DebugView()
	}
}
