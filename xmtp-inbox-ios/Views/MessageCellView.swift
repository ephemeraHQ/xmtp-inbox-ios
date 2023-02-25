//
//  MessageCellView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/7/22.
//

import OpenGraph
import SwiftUI
import XMTP

struct MessageCellView: View {
	var message: DB.Message

	@State private var isLoading = false
	@State private var preview: URLPreview?

	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				if message.isFromMe {
					Spacer()
				}
				VStack {
					if let preview = message.preview {
						URLPreviewView(preview: preview)
							.foregroundColor(textColor)
							.padding()
							.background(background)
					} else if message.isBareImageURL, let url = URL(string: message.body), Settings.shared.showImageURLs {
						RemoteMediaView(message: message, url: url)
					} else {
						MessageTextView(content: message.body, textColor: UIColor(textColor)) { url in
							print("URL \(url)")
						}
						.foregroundColor(textColor)
						.padding()
						.background(background)
					}
				}

				if !message.isFromMe {
					Spacer()
				}
			}
		}
	}

	var background: some View {
		if message.isFromMe {
			return Color.actionPrimary.roundCorners(16, corners: [.topLeft, .topRight, .bottomLeft])
		} else {
			return Color.backgroundSecondary.roundCorners(16, corners: [.topRight, .bottomLeft, .bottomRight])
		}
	}

	var textColor: Color {
		if message.isFromMe {
			return .actionPrimaryText
		} else {
			return .textPrimary
		}
	}
}

#if DEBUG
struct MessageCellView_Previews: PreviewProvider {
	static var previews: some View {
		FullScreenContentProvider {
			List {
				MessageCellView(message: DB.Message.preview)
				MessageCellView(message: DB.Message.previewImage)
				MessageCellView(message: DB.Message.previewGIF)
				MessageCellView(message: DB.Message.previewWebP)
				MessageCellView(message: DB.Message.previewMP4) // TODO: add a video player
			}
			.listStyle(.plain)
		}
	}
}
#endif
