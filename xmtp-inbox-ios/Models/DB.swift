//
//  DB.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import Combine
import CryptoKit
import Foundation
import GRDB
import XMTP

struct DB {
	var queue: DatabaseQueue

	// If we need to totally blow away the DB, increment this
	static let version = 31

	enum DBError: Error {
		case badData(String)
	}

	static func load(client: Client) throws -> DB? {
		guard let location = AppGroup.defaults.string(forKey: "dbLocation") else {
			return nil
		}

		let passphraseData = try client.privateKeyBundle.serializedData()
		let passphrase = Data(SHA256.hash(data: passphraseData)).toHex
		let config = configFor(passphrase: passphrase)
		let queue = try DatabaseQueue(path: location, configuration: config)
		let db = DB(queue: queue)

		return db
	}

	static func prepareTest() -> DB {
		// swiftlint:disable force_try
		let queue = try! DatabaseQueue(named: UUID().uuidString)
		let db = DB(queue: queue)
		try! db.createTables()
		// swiftlint:enable force_try
		return db
	}

	static func prepare(
		client: XMTP.Client,
		name: String = "db-\(DB.version).sqlite",
		reset: Bool = false,
		isRetry: Bool = false
	) throws -> DB {
		let location = AppGroup.containerURL.appendingPathComponent(name)

		if reset {
			do {
				try FileManager.default.removeItem(at: location)
			} catch {
				print("Error removing db at \(location)")
			}
		}

		let passphraseData = try client.privateKeyBundle.serializedData()
		let passphrase = Data(SHA256.hash(data: passphraseData)).toHex

		let config = configFor(passphrase: passphrase)
		let queue = try DatabaseQueue(path: location.absoluteString, configuration: config)
		let db = DB(queue: queue)
		try db.createTables()

		AppGroup.defaults.set(location.absoluteString, forKey: "dbLocation")

		return db
	}

	static func configFor(passphrase: String) -> Configuration {
		var config = Configuration()

		config.prepareDatabase { db in
			try db.usePassphrase(passphrase)

			#if DEBUG
//				db.trace { print("SQL: \($0)") }
//				config.publicStatementArguments = true
			#endif
		}

		return config
	}

	func createTables() throws {
		try queue.write { db in
			try DB.Conversation.createTable(db: db)
			try DB.ConversationTopic.createTable(db: db)
			try DB.Message.createTable(db: db)
			try DB.MessageAttachment.createTable(db: db)
			try DB.RemoteAttachment.createTable(db: db)
		}
	}

	func clear() throws {
		try queue.write { db in
			try DB.ConversationTopic.clear(db: db)
			try DB.Conversation.clear(db: db)
			try DB.RemoteAttachment.clear(db: db)
			try DB.MessageAttachment.clear(db: db)
			try DB.Message.clear(db: db)
		}
	}
}
