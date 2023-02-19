//
//  MessageCellView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/7/22.
//

import NukeUI
import OpenGraph
import SwiftUI
import XMTP

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

struct MessageCellView: View {
	var message: DB.Message

	@State private var isLoading = false
	@State private var preview: URLPreview?

	@Environment(\.fullScreenContent) var fullScreenContent

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
					} else if message.isBareImageURL {
						if let image = ImageCache.shared.load(url: URL(string: message.body)) {
							image
								.resizable()
								.scaledToFit()
								.aspectRatio(contentMode: .fit)
								.frame(height: 200)
								.background(.blue)
								.cornerRadius(12)
								.fullScreenable(content: .image(image))
						}

//							LazyImage(url: URL(string: message.body)) { state in
//								if let image = state.image {
//									image
//										.resizable()
//										.scaledToFit()
//										.aspectRatio(contentMode: .fit)
//										.frame(height: 200)
//										.background(.blue)
//										.cornerRadius(12)
//								} else if state.error != nil {
//									Color.red // Indicates an error.
//								} else {
//									Color.blue // Acts as a placeholder.
//								}
//							}

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

struct MessageCellView_Previews: PreviewProvider {
	static var previews: some View {
		List {
			MessageCellView(message: DB.Message.previewImage)
		}
		.listStyle(.plain)
	}
}
