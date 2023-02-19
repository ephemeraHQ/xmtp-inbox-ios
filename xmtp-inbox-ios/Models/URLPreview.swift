//
//  URLPreview.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/18/23.
//

import Foundation

struct URLPreview: Codable {
	var url: URL
	var title: String
	var description: String?
	var imageURL: String?
	var imageData: Data?
}
