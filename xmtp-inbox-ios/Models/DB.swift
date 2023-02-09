//
//  DB.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import Foundation
import GRDB

class DB {
	// If we need to totally blow away the DB, increment this
	static let version = 2

	enum DBError: Error {
		case badData(String)
	}

	static let shared = DB()

	enum Mode {
		case normal, test
	}

	var mode: Mode = .normal
	var config: Configuration = .init()

	// swiftlint:disable force_try
	// Set up a default DB queue that's just in memory
	var queue: DatabaseQueue = try! DatabaseQueue(named: "memory")
	// swiftlint:enable force_try

	// It's a singleton
	private init() {}

	func prepare(passphrase: String, mode: Mode = .normal, reset: Bool = false) throws {
		self.mode = mode

		if reset {
			// swiftlint:disable no_optional_try
			try? FileManager.default.removeItem(at: location)
			// swiftlint:enable no_optional_try
		}

		config.prepareDatabase { db in
			try db.usePassphrase(passphrase)

			#if DEBUG
				db.trace { print("SQL: \($0)") }
				self.config.publicStatementArguments = true
			#endif
		}

		queue = try DatabaseQueue(path: location.absoluteString, configuration: config)

		try createTables()
	}

	func createTables() throws {
		try queue.write { db in
			try DB.Conversation.createTable(db: db)
			try DB.Message.createTable(db: db)
		}
	}

	var location: URL {
		URL.documentsDirectory.appendingPathComponent("db\(mode == .normal ? "" : "-test-v\(DB.version)").sqlite")
	}
}
