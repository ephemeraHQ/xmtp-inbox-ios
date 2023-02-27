//
//  AttachmentUnknownView.swift
//  xmtp-inbox-ios
//
//  Created by Pat Nakajima on 2/26/23.
//

import Foundation
import SwiftUI

struct AttachmentUnknownView: View {
	var attachment: DB.MessageAttachment

	var body: some View {
		VStack {
			Image(systemName: "doc")
				.resizable()
				.scaledToFit()
				.foregroundColor(.secondary)
				.frame(width: 32, height: 32)
				.fontWeight(.ultraLight)
			Text(attachment.filename)
				.font(.caption)
				.foregroundColor(.secondary)
		}
		.padding()
		.background(.thinMaterial)
		.cornerRadius(8)
		.fullScreenable(url: attachment.location)
	}
}

#if DEBUG
	struct AttachmentUnknownView_Previews: PreviewProvider {
		static var previews: some View {
			FullScreenContentProvider {
				AttachmentUnknownView(attachment: DB.Message.previewTxt.attachments[0])
			}
		}
	}
#endif
