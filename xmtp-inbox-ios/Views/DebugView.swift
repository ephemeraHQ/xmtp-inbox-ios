//
//  DebugView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/13/23.
//

import SwiftUI

struct EnvironmentToggleView: View {
	@EnvironmentObject var environmentCoordinator: EnvironmentCoordinator
	@EnvironmentObject var auth: Auth

	@Environment(\.dismiss) var dismiss

	var body: some View {
		HStack {
			Text(label)
			Spacer()
			Button(action: toggle) {
				Text("Switch to \(other)")
			}
		}
	}

	func toggle() {
		if XMTPEnvironmentManager.shared.environment == .production {
			XMTPEnvironmentManager.shared.environment = .dev
		} else {
			XMTPEnvironmentManager.shared.environment = .production
		}

		auth.signOut()
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
	var body: some View {
		NavigationStack {
			List {
				Section("Local Storage") {
					NavigationLink(destination: SQLDebuggerView()) {
						Text("SQL Debugger")
					}
					Button("Clear DB") {
						do {
							try DB.clear()
						} catch {
							Flash.add(.error("Error clearing the DB: \(error)"))
						}
					}
				}

				Section("XMTP Environment") {
					EnvironmentToggleView()
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
