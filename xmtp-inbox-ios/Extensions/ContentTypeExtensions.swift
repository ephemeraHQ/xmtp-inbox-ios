//
//  ContentTypeExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/25/23.
//

import XMTP

extension ContentTypeID: Codable {
	enum CodingKeys: CodingKey {
		case authorityID, typeID, versionMajor, versionMinor
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(authorityID, forKey: .authorityID)
		try container.encode(typeID, forKey: .typeID)
		try container.encode(versionMajor, forKey: .versionMajor)
		try container.encode(versionMinor, forKey: .versionMinor)
	}

	public init(from decoder: Decoder) throws {
		self.init()

		let container = try decoder.container(keyedBy: CodingKeys.self)
		authorityID = try container.decode(String.self, forKey: .authorityID)
		typeID = try container.decode(String.self, forKey: .typeID)
		versionMajor = try container.decode(UInt32.self, forKey: .versionMajor)
		versionMinor = try container.decode(UInt32.self, forKey: .versionMinor)
	}
}

extension ContentTypeID: Equatable {
	static func == (lhs: ContentTypeID, rhs: ContentTypeID) -> Bool {
		return lhs.authorityID == rhs.authorityID && lhs.typeID == rhs.typeID && lhs.versionMajor == rhs.versionMajor && lhs.versionMinor == rhs.versionMinor
	}
}
