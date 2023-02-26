//
//  AttachmentView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/25/23.
//

import SwiftUI

struct AttachmentView: View {
	var attachment: DB.MessageAttachment

	var body: some View {
		switch attachment.type {
		case .image:
			AttachmentImageView(attachment: attachment)
		}
	}
}

#if DEBUG
	struct AttachmentView_Previews: PreviewProvider {
		static var previews: some View {
			AttachmentView(attachment: DB.MessageAttachment.previewImage)
		}
	}
#endif
