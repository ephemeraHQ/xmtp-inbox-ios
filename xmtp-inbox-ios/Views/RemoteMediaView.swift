//
//  RemoteImageView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/19/23.
//

import SDWebImageSwiftUI
import SwiftUI

struct RemoteMediaView: View {
	var message: DB.Message
	var url: URL

	var body: some View {
		if isAnimated {
			AnimatedImage(url: URL(string: message.body))
				.resizable()
				.scaledToFit()
				.aspectRatio(contentMode: .fit)
				.frame(height: 200)
				.cornerRadius(12)
				.fullScreenable(url: url)
		} else {
			WebImage(url: URL(string: message.body))
				.resizable()
				.scaledToFit()
				.aspectRatio(contentMode: .fit)
				.frame(height: 200)
				.cornerRadius(12)
				.fullScreenable(url: url)
		}
	}

	var isVideo: Bool {
		["mp4", "gifv"].contains(url.pathExtension)
	}

	var isAnimated: Bool {
		["webp", "gif"].contains(url.pathExtension)
	}
}

struct RemoteImageView_Previews: PreviewProvider {
	static var previews: some View {
		// swiftlint:disable force_unwrapping
		RemoteMediaView(message: DB.Message.previewGIF, url: URL(string: DB.Message.previewGIF.body)!)
	}
}
