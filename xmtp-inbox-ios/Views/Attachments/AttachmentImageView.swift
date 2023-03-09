//
//  AttachmentImageView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/25/23.
//

import SwiftUI

struct AttachmentImageView: View {
	var attachment: DB.MessageAttachment

	var body: some View {
		VStack(alignment: .leading) {
			if let uiImage = UIImage(contentsOfFile: attachment.location.path) {
				Image(uiImage: uiImage)
					.resizable()
					.scaledToFit()
					.frame(maxWidth: 200)

			} else {
				Text("Invalid image data.")
			}

			VStack(alignment: .leading) {
				Text(attachment.filename)
			}
			.padding(.horizontal, 8)
			.padding(.bottom, 8)
			.foregroundColor(.secondary)
			.font(.caption)
		}
		.background(.ultraThinMaterial)
		.fullScreenable(url: attachment.location)
	}
}

#if DEBUG
struct AttachmentImageView_Previews: PreviewProvider {
	static var previews: some View {
		AttachmentImageView(attachment: DB.MessageAttachment.previewImage)
	}
}
#endif
