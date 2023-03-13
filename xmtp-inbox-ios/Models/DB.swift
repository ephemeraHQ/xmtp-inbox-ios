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

actor DB {
	// If we need to totally blow away the DB, increment this
	static let version = -25

	enum DBError: Error {
		case badData(String)
	}

	private static let shared = DB()

	static var _queue: DatabaseQueue {
		get async {
			await shared.queue
		}
	}

	static func prepareTest(client _: XMTP.Client) async throws {
		try await shared.prepare(passphrase: "TEST", reset: true)
	}

	static func prepare(client: XMTP.Client, reset: Bool = false, isRetry: Bool = false) async throws {
		let dbVersion = AppGroup.defaults.integer(forKey: "dbVersion")

		let passphraseData = try client.privateKeyBundle.serializedData()
		let passphrase = Data(SHA256.hash(data: passphraseData)).toHex

		do {
			try await shared.prepare(passphrase: passphrase, reset: reset || (dbVersion != DB.version))
		} catch {
			if isRetry {
				throw error
			} else {
				print("ERROR PREPARE: \(error). Retrying with reset...")
				try await DB.prepare(client: client, reset: true, isRetry: true)
			}
		}

		AppGroup.defaults.set(DB.version, forKey: "dbVersion")
	}

	static func read<T>(perform: (Database) throws -> T) async throws -> T {
		try await shared.queue.read(perform)
	}

	static func write<T>(perform: (Database) throws -> T) async throws -> T {
		try await shared.queue.write(perform)
	}

	static func clear() async throws {
		try await shared.clear()
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

	func prepare(passphrase: String, mode: Mode = .normal, reset: Bool = false) async throws {
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

		try await createTables()
	}

	func createTables() async throws {
		try await queue.write { db in
			try DB.Conversation.createTable(db: db)
			try DB.ConversationTopic.createTable(db: db)
			try DB.Message.createTable(db: db)
			try DB.MessageAttachment.createTable(db: db)
			try DB.RemoteAttachment.createTable(db: db)
		}
	}

	func clear() async throws {
		try await queue.write { db in
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
