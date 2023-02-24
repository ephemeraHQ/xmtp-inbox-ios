//
//  EnvironmentValueExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/23/23.
//

import Foundation
import GRDB
import SwiftUI

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
}
