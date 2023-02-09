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
		do {
			return try DB.shared.queue.read { db in
				try find(db, key: id)
			}
		} catch {
			print("Error finding by ID (\(id)): \(error)")
			return nil
		}
	}

	static func find(_ predicate: SQLSpecificExpressible) -> Self? {
		do {
			return try DB.shared.queue.read { db in
				try filter(predicate).fetchOne(db)
			}
		} catch {
			print("Error finding \(predicate) : \(error)")
			return nil
		}
	}

	mutating func save() throws {
		try DB.shared.queue.write { db in
			try insert(db, onConflict: .replace)
		}
	}

	mutating func didInsert(_ inserted: InsertionSuccess) {
		id = Int(inserted.rowID)
	}
}
