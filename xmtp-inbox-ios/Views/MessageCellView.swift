//
//  MessageCellView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/7/22.
//

import OpenGraph
import SwiftUI
import XMTP

struct TextMessageView: View {
	var message: DB.Message

	var body: some View {
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
	}

	var textColor: Color {
		if message.isFromMe {
			return .actionPrimaryText
		} else {
			return .textPrimary
		}
	}

	var background: some View {
		if message.isFromMe {
			return Color.actionPrimary.roundCorners(16, corners: [.topLeft, .topRight, .bottomLeft])
		} else {
			return Color.backgroundSecondary.roundCorners(16, corners: [.topRight, .bottomLeft, .bottomRight])
		}
	}
}

struct UnloadedAttachmentMessageView: View {
	var presenter: MessagePresenter
	var message: DB.Message
	var remoteAttachments: [DB.RemoteAttachment]

	var body: some View {
		ForEach(remoteAttachments) { attachment in
			RemoteAttachmentMessageView(presenter: presenter, message: message, attachment: attachment)
		}
	}
}

struct LoadedAttachmentMessageView: View {
	var message: DB.Message

	var body: some View {
		ForEach(message.attachments) { attachment in
			VStack {
				AttachmentView(attachment: attachment)
					.cornerRadius(8)
			}
		}
	}
}

struct UnknownContentTypeMessageView: View {
	var message: DB.Message

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(message.fallbackContent ?? "No fallback content.")
			Text("Unknown message type")
				.font(.caption2)
				.foregroundColor(.secondary)
		}
		.padding()
		.background(.ultraThinMaterial)
		.cornerRadius(8)
	}
}

struct MessageCellView: View {
	var message: DB.Message

	@State private var isLoading = false
	@State private var preview: URLPreview?
	@StateObject private var presenter: MessagePresenter

	init(message: DB.Message, preview: URLPreview? = nil) {
		self.message = message
		self.isLoading = isLoading
		self.preview = preview
		self._presenter = StateObject(wrappedValue: MessagePresenter(message: message))
	}

	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				if message.isFromMe {
					Spacer()
				}

				VStack {
					switch message.contentType {
					case ContentTypeText:
						TextMessageView(message: presenter.message)
					case ContentTypeRemoteAttachment, ContentTypeAttachment:
						if presenter.message.attachments.isEmpty {
							UnloadedAttachmentMessageView(presenter: presenter, message: presenter.message, remoteAttachments: message.remoteAttachments)
						} else {
							LoadedAttachmentMessageView(message: presenter.message)
						}
					default:
						UnknownContentTypeMessageView(message: presenter.message)
					}
				}

				if !message.isFromMe {
					Spacer()
				}
			}
		}
		.onTapGesture {
			print("\(message)")
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
		FullScreenContentProvider {
			List {
				MessageCellView(message: DB.Message.preview)
					.listRowSeparator(.hidden)
				MessageCellView(message: DB.Message.previewUnsavedImageAttachment)
					.listRowSeparator(.hidden)
				MessageCellView(message: DB.Message.previewSavedImageAttachment)
					.listRowSeparator(.hidden)
				MessageCellView(message: DB.Message.previewUnknown)
					.listRowSeparator(.hidden)
				MessageCellView(message: DB.Message.previewImage)
					.listRowSeparator(.hidden)
				MessageCellView(message: DB.Message.previewGIF)
					.listRowSeparator(.hidden)
				MessageCellView(message: DB.Message.previewWebP)
					.listRowSeparator(.hidden)
				MessageCellView(message: DB.Message.previewMP4) // TODO: add a video player
					.listRowSeparator(.hidden)
			}
			.listStyle(.plain)
		}
	}
}
