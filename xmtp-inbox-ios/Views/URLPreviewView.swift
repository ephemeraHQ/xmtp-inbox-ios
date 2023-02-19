//
//  URLPreviewView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/19/23.
//

import SwiftUI

struct URLPreviewView: View {
	var preview: URLPreview

	var body: some View {
		HStack(alignment: .top) {
			if let imageData = preview.imageData, let uiImage = UIImage(data: imageData) {
				Image(uiImage: uiImage)
					.resizable()
					.scaledToFit()
					.frame(width: 24, height: 24)
			}

			VStack(alignment: .leading, spacing: 8) {
				Text(preview.title)
					.font(.caption)
					.bold()
				Text(preview.url.absoluteString)
					.font(.caption)
					.foregroundColor(.secondary)
			}
		}
		.onTapGesture {
			UIApplication.shared.open(preview.url)
		}
	}
}

struct URLPreviewView_Previews: PreviewProvider {
	static var previews: some View {
		URLPreviewView(preview: URLPreview(
			// swiftlint:disable force_unwrapping
			url: URL(string: "https://example.com")!,
			title: "Hi"
		))
	}
}
