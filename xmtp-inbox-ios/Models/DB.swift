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

class DB {
	// If we need to totally blow away the DB, increment this
	static let version = -24

	enum DBError: Error {
		case badData(String)
	}

	private static let shared = DB()

	static var _queue: DatabaseQueue {
		shared.queue
	}

	static func prepareTest(client _: XMTP.Client) throws {
		shared.mode = .test
		shared.queue = try DatabaseQueue()
		try shared.prepare(passphrase: "TEST", reset: true)
	}

	static func prepare(client: XMTP.Client, reset: Bool = false, isRetry: Bool = false) throws {
		let dbVersion = AppGroup.defaults.integer(forKey: "dbVersion")

		let passphraseData = try client.privateKeyBundle.serializedData()
		let passphrase = Data(SHA256.hash(data: passphraseData)).toHex

		do {
			try shared.prepare(passphrase: passphrase, reset: reset || (dbVersion != DB.version))
		} catch {
			if isRetry {
				throw error
			} else {
				print("ERROR PREPARE: \(error). Retrying with reset...")
				try DB.prepare(client: client, reset: true, isRetry: true)
			}
		}

		AppGroup.defaults.set(DB.version, forKey: "dbVersion")
	}

	static func read<T>(perform: (Database) throws -> T) throws -> T {
		try shared.queue.read(perform)
	}

	static func write<T>(perform: (Database) throws -> T) throws -> T {
		try shared.queue.write(perform)
	}

	static func clear() throws {
		try shared.clear()
	}

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
			do {
				try FileManager.default.removeItem(at: location)
			} catch {
				print("Error removing db at \(location)")
			}
		}

		config.prepareDatabase { db in
			try db.usePassphrase(passphrase)

			#if DEBUG
//				db.trace { print("SQL: \($0)") }
//				self.config.publicStatementArguments = true
			#endif
		}

		queue = try DatabaseQueue(path: location.absoluteString, configuration: config)

		try createTables()
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
			try DB.ConversationTopic.deleteAll(db)
			try DB.Conversation.deleteAll(db)
			try DB.RemoteAttachment.deleteAll(db)
			try DB.MessageAttachment.deleteAll(db)
			try DB.Message.deleteAll(db)
		}
	}

	var location: URL {
		AppGroup.containerURL.appendingPathComponent("db\(mode == .normal ? "" : "-test-v\(DB.version)")-\(Constants.xmtpEnv).sqlite")
	}
}
