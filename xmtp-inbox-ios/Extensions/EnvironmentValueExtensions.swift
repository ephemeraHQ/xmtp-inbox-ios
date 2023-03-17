//
//  EnvironmentValueExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/23/23.
//

import Foundation
import GRDB
import SwiftUI

private struct DBKey: EnvironmentKey {
	static var defaultValue: DB { DB.prepareTest() }
}

private struct DatabaseQueueKey: EnvironmentKey {
	// swiftlint:disable force_try
	static var defaultValue: DatabaseQueue { try! DatabaseQueue() }
	// swiftlint:enable force_try
}

extension EnvironmentValues {
	var dbQueue: DatabaseQueue {
		get { self[DatabaseQueueKey.self] }
		set { self[DatabaseQueueKey.self] = newValue }
	}

	var db: DB {
		get { self[DBKey.self] }
		set { self[DBKey.self] = newValue }
	}
}
