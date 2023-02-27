//
//  AttachmentExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/24/23.
//

import XMTP

extension XMTP.Attachment: Equatable {
	public static func == (lhs: Attachment, rhs: Attachment) -> Bool {
		lhs.mimeType == rhs.mimeType && lhs.filename == rhs.filename && lhs.data == rhs.data
	}

	var type: DB.MessageAttachment.ContentType {
		if DB.MessageAttachment.ContentType.imageTypes.contains(mimeType) {
			return .image
		}

		return .unknown
	}
}
