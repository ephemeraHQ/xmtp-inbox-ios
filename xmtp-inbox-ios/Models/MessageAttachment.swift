//
//  MessageAttachment.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/14/23.
//

import Foundation
import GRDB
import XMTP

extension DB {
	struct MessageAttachment: Codable {
		var id: Int?
		var messageID: Int
		var mimeType: String
		var filename: String
		var uuid: UUID

		var toXMTP: XMTP.Attachment? {
			do {
				return XMTP.Attachment(filename: filename, mimeType: mimeType, data: try Data(contentsOf: location))
			} catch {
				print("ERROR TO XMTP \(error)")
				return nil
			}
		}

		var location: URL {
			attachmentsDirectory.appendingPathComponent("\(uuid.uuidString)")
		}

		var attachmentsDirectory: URL {
			URL.documentsDirectory.appendingPathComponent("attachments")
		}

		func save(data: Data) throws {
			try FileManager.default.createDirectory(at: attachmentsDirectory, withIntermediateDirectories: true)

			try data.write(to: location)
		}
	}
}

extension DB.MessageAttachment: Model {
	static func createTable(db: GRDB.Database) throws {
		try db.create(table: "messageAttachment", ifNotExists: true) { t in
			t.autoIncrementedPrimaryKey("id")
			t.column("messageID", .integer).notNull().references("message")
			t.column("uuid", .text).notNull().unique()
			t.column("mimeType", .text).notNull()
			t.column("filename", .text).notNull()
		}
	}
}
