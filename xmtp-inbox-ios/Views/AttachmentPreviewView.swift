//
//  AttachmentPreviewView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/24/23.
//

import SwiftUI
import XMTP

struct ImageAttachmentView: View {
	var attachment: XMTP.Attachment
	@State private var image: Image?

	var body: some View {
		if let image {
			image
				.resizable()
				.scaledToFit()
				.aspectRatio(contentMode: .fit)
				.frame(height: 100)
				.cornerRadius(12)
		} else {
			ProgressView()
				.onAppear {
					if let uiImage = UIImage(data: attachment.data) {
						self.image = Image(uiImage: uiImage)
					} else {
						print("NO IMAGE in preview")
					}
				}
		}
	}
}

struct AttachmentPreviewView: View {
	var attachment: XMTP.Attachment

	init(attachment: XMTP.Attachment) {
		self.attachment = attachment
	}

	var body: some View {
		switch attachment.type {
		case .image:
			ImageAttachmentView(attachment: attachment)
		case .unknown:
			Text("Unknown Content Type")
		}
	}
}

struct AttachmentPreviewViwe_Previews: PreviewProvider {
	static var previews: some View {
		ZStack {
			// swiftlint:disable force_unwrapping
			AttachmentPreviewView(attachment: XMTP.Attachment(filename: "hello.txt", mimeType: "image/png", data: (UIImage(named: "XMTPGraphic")?.pngData()!)!))
		}
	}
}
