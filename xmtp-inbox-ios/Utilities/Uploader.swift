//
//  Uploader.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/20/23.
//

import Foundation

protocol Uploader {
	func upload(data: Data) async throws -> String
}

struct TestUploader: Uploader {
	var uuid = UUID()

	func upload(data _: Data) async throws -> String {
		"https://hi"
	}
}
