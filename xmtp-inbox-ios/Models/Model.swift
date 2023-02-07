//
//  Model.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import GRDB

protocol Model: Identifiable, Codable, MutablePersistableRecord, FetchableRecord {
	static func createTable(db: GRDB.Database) throws

	// We've always got a DB ID
	var id: Int? { get set }
}

extension Model {
	static func list() -> [Self] {
		do {
			return try DB.shared.queue.read { db in
				try fetchAll(db)
			}
		} catch {
			print("Error loading all \(databaseTableName): \(error)")
			return []
		}
	}

	static func list(order: SQLOrderingTerm) -> [Self] {
		do {
			return try DB.shared.queue.read { db in
				try self
					.order([order])
					.fetchAll(db)
			}
		} catch {
			print("Error loading all \(databaseTableName): \(error)")
			return []
		}
	}

	static func find(id: Int) -> Self? {
		// swiftlint:disable no_optional_try
		try? DB.shared.queue.read { db in
			try? find(db, key: id)
		}
		// swiftlint:enable no_optional_try
	}

	static func find(_ predicate: SQLSpecificExpressible) -> Self? {
		// swiftlint:disable no_optional_try
		try? DB.shared.queue.read { db in
			try? filter(predicate).fetchOne(db)
		}
		// swiftlint:enable no_optional_try
	}

	mutating func save() throws {
		try DB.shared.queue.write { db in
			try insert(db, onConflict: .replace)
		}
	}

	mutating func didInsert(_ inserted: InsertionSuccess) {
		id = Int(inserted.rowID)
	}

	mutating func didUpdate(_ updated: PersistenceSuccess) {
		if let id = updated.persistenceContainer["id"] as? UInt64 {
			self.id = Int(id)
		}
	}
}
