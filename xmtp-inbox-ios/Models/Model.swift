//
//  Model.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/2/23.
//

import GRDB

protocol Model: Codable, MutablePersistableRecord, FetchableRecord {
	static func createTable(db: GRDB.Database) throws

	var id: Int? { get set }
}

extension Model {
	static func find(id: Int) -> Self? {
		// swiftlint:disable no_optional_try
		try? DB.shared.queue.read { db in
			try? Self.find(db, key: id)
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
}
