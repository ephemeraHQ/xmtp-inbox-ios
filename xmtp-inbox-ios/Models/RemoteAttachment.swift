//
//  RemoteAttachment.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/25/23.
//

import GRDB

extension DB {
	struct RemoteAttachment {
		var id: Int?
		var messageID: Int = -1

		var url: String
		var salt: Data
		var nonce: Data
		var secret: Data
		var contentDigest: String

		// Not part of spec
		var filename: String?
		var contentLength: Int?
	}
}

extension DB.RemoteAttachment: Model {
	static func createTable(db: GRDB.Database) throws {
		try db.create(table: "remoteAttachment", ifNotExists: true) { t in
			t.autoIncrementedPrimaryKey("id")
			t.column("messageID", .integer).notNull().indexed()
			t.column("url", .text).notNull()
			t.column("salt", .blob).notNull()
			t.column("nonce", .blob).notNull()
			t.column("secret", .blob).notNull()
			t.column("contentDigest", .text).notNull()
			t.column("filename", .text)
			t.column("contentLength", .integer)
		}
	}
}

#if DEBUG
	extension DB.RemoteAttachment {
		static var previewImage: DB.RemoteAttachment {
			DB.RemoteAttachment(messageID: 1, url: "https://example.com", salt: Data(), nonce: Data(), secret: Data(), contentDigest: "HI", filename: "icon.png", contentLength: 12311)
		}
	}
#endif
