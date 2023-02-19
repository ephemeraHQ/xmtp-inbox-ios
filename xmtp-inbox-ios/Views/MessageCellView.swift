//
//  MessageCellView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/7/22.
//

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

struct MessageTextView: UIViewRepresentable {
	var content: String
	var textColor: UIColor
	var openURL: (URL) -> Void

	class Coordinator: NSObject, UITextViewDelegate {
		var content: String
		var openURL: (URL) -> Void
		var view: UITextView

		init(content: String, textColor: UIColor, openURL: @escaping (URL) -> Void) {
			self.content = content
			self.openURL = openURL
			view = UITextView()

			view.backgroundColor = .clear
			view.text = content

			view.isEditable = false
			view.isScrollEnabled = false
			view.dataDetectorTypes = .link

			view.textColor = textColor

			view.font = UIFont.preferredFont(forTextStyle: .body)

			// Remove padding
			view.textContainerInset = .zero
			view.textContainer.lineFragmentPadding = .zero

			super.init()
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(content: content, textColor: textColor, openURL: openURL)
	}

	func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context _: Context) -> CGSize? {
		let height = uiView.sizeThatFits(CGSize(width: proposal.width ?? .infinity, height: proposal.height ?? .infinity))
		return height
	}

	func makeUIView(context: Context) -> UITextView {
		return context.coordinator.view
	}

	func updateUIView(_ uiView: UITextView, context _: Context) {
		uiView.text = content
	}
}

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
					} else {
						MessageTextView(content: message.body, textColor: UIColor(textColor)) { url in
							print("URL \(url)")
						}
					}
				}
				.foregroundColor(textColor)
				.padding()
				.background(background)

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
			MessageCellView(message: DB.Message.preview)
		}
		.listStyle(.plain)
	}
}
