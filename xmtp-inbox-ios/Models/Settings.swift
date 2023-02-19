//
//  Settings.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/18/23.
//

import Foundation
import SwiftUI

class Settings: ObservableObject {
	static let shared = Settings()

	@Published var showLinkPreviews: Bool = true {
		didSet { persist("showLinkPreviews", showLinkPreviews) }
	}

	@Published var showImageURLs: Bool = true {
		didSet { persist("showImageURLs", showImageURLs) }
	}

	private init() {
		showLinkPreviews = AppGroup.defaults.bool(forKey: "showLinkPreviews")
		showImageURLs = AppGroup.defaults.bool(forKey: "showImageURLs")
	}

	func persist<T>(_ name: String, _ val: T) {
		AppGroup.defaults.set(val, forKey: name)
	}
}
