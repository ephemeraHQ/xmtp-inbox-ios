//
//  Model.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import GRDB

protocol Model: Identifiable, Codable, Hashable, MutablePersistableRecord, FetchableRecord {
	static func createTable(db: GRDB.Database) throws

	// We've always got a DB ID
	var id: Int? { get set }
}

struct StaticModelProxy<T: Model> {
	var db: DB

	func `where`(_ predicate: SQLSpecificExpressible) -> [T] {
		do {
			return try db.queue.read { db in
				try T.filter(predicate).fetchAll(db)
			}
		} catch {
			print("Error finding \(predicate) : \(error)")
			return []
		}
	}

	func list() -> [T] {
		do {
			return try db.queue.read { db in
				try T.fetchAll(db)
			}
		} catch {
			print("Error loading all \(T.databaseTableName): \(error)")
			return []
		}
	}

	func list(order: SQLOrderingTerm) -> [T] {
		do {
			return try db.queue.read { db in
				try T
					.order([order])
					.fetchAll(db)
			}
		} catch {
			print("Error loading all \(T.databaseTableName): \(error)")
			return []
		}
	}

	func find(id: Int) -> T? {
		do {
			return try db.queue.read { db in
				try T.find(db, key: id)
			}
		} catch {
			print("Error finding by ID (\(id)): \(error)")
			return nil
		}
	}

	func find(_ predicate: SQLSpecificExpressible) -> T? {
		do {
			return try db.queue.read { db in
				try T.filter(predicate).fetchOne(db)
			}
		} catch {
			print("Error finding \(predicate) : \(error)")
			return nil
		}
	}
}

extension Model {
	static func using(db: DB) -> StaticModelProxy<Self> {
		StaticModelProxy(db: db)
	}

	static func clear(db: Database) throws {
		try deleteAll(db)
		try db.drop(table: databaseTableName)
	}

	mutating func save(db: DB) throws {
		do {
			try db.queue.write { db in
				try insert(db, onConflict: .replace)
			}
		} catch {
			print("Error saving \(self): \(error)")
		}
	}

	mutating func didInsert(_ inserted: InsertionSuccess) {
		id = Int(inserted.rowID)
	}
}
