//
//  MessageObserver.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/17/23.
//

import GRDB

class MessageObserver: TransactionObserver {
	var callback: () -> Void

	init(callback: @escaping () -> Void) {
		self.callback = callback
	}

	func databaseDidCommit(_: GRDB.Database) {}
	func databaseDidRollback(_: GRDB.Database) {}

	func databaseDidChange(with _: GRDB.DatabaseEvent) {
		callback()
		stopObservingDatabaseChangesUntilNextTransaction()
	}

	func observes(eventsOfKind eventKind: DatabaseEventKind) -> Bool {
		if case let .insert(tableName) = eventKind, tableName == "message" {
			return true
		} else {
			return false
		}
	}
}
