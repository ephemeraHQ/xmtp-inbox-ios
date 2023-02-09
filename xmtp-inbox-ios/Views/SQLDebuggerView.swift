//
//  SQLDebuggerView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/8/23.
//

import GRDB
import SwiftUI

struct SQLDebuggerView: View {
	@State private var sql: String = "select * from conversation"
	@State private var results: [String] = []

	var body: some View {
		List {
			TextEditor(text: $sql)
				.font(.system(.body, design: .monospaced))
				.autocapitalization(.none)
				.autocorrectionDisabled(true)
				.lineLimit(4, reservesSpace: true)
			Button("Run") {
				do {
					let results = try DB.shared.queue.read { db in
						try Row.fetchAll(db, sql: sql)
					}

					self.results = results.map(\.debugDescription)
				} catch {
					print("Error running query: \(error)")
				}
			}
			Section {
				ForEach(results, id: \.self) { result in
					Text(result)
						.font(.system(.body, design: .monospaced))
				}
			}
		}
		.navigationTitle("SQL Debugger")
		.navigationBarTitleDisplayMode(.inline)
	}
}

struct SQLDebuggerView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			SQLDebuggerView()
		}
	}
}
