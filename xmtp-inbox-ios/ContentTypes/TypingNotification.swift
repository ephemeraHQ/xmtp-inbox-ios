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
	public init() {}

	public var contentType = ContentTypeTypingNotification

	public func encode(content: TypingNotification) throws -> EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeTypingNotification
		encodedContent.content = try JSONEncoder().encode(content)

		return encodedContent
	}

	public func decode(content: EncodedContent) throws -> TypingNotification {
		let decoder = JSONDecoder()
		return try decoder.decode(TypingNotification.self, from: content.content)
	}
}
