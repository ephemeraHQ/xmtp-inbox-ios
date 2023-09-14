//
//  TypingNotification.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 4/1/23.
//

import Foundation
import XMTP

public let ContentTypeTypingNotification = ContentTypeID(
	authorityID: "xmtp.com",
	typeID: "typingNotification",
	versionMajor: 1,
	versionMinor: 0
)

public struct TypingNotification: Codable {
	var timestamp: Date
	var typerAddress: String
	var isFinished: Bool
}

public struct TypingNotificationCodec: ContentCodec {
	enum Error: Swift.Error {
		case missingParameter(String)
	}

	public init() {}

	public var contentType = ContentTypeTypingNotification

	var dateFormatter: ISO8601DateFormatter {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions.insert(.withFractionalSeconds)
		return formatter
	}

	public func encode(content: TypingNotification) throws -> EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeTypingNotification
		encodedContent.parameters["timestamp"] = dateFormatter.string(from: content.timestamp)
		encodedContent.parameters["typerAddress"] = content.typerAddress
		encodedContent.parameters["isFinished"] = content.isFinished ? "true" : "false"
		encodedContent.content = Data()

		return encodedContent
	}

	public func decode(content: EncodedContent) throws -> TypingNotification {
		print("PARM: \(content.parameters)")

		guard let timestampString = content.parameters["timestamp"] else {
			throw Error.missingParameter("missing timestamp parameter")
		}

		guard let timestamp = dateFormatter.date(from: timestampString) else {
			throw Error.missingParameter("invalid timestamp")
		}

		guard let typerAddress = content.parameters["typerAddress"] else {
			throw Error.missingParameter("missing typerAddress parameter")
		}

		let isFinished = content.parameters["isFinished"] == "true"

		return TypingNotification(timestamp: timestamp, typerAddress: typerAddress, isFinished: isFinished)
	}
}
