//
//  RemoteAttachmentMessageView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/25/23.
//

import SwiftUI
import XMTP

struct RemoteAttachmentMessageView: View {
	var presenter: MessagePresenter
	var message: DB.Message
	var attachment: DB.RemoteAttachment

	@State private var isLoading = false
	@State private var error: String?

	var body: some View {
		VStack {
			Button("Tap to Load Attachment") {
				withAnimation {
					load()
				}
			}
			.opacity((isLoading || error != nil) ? 0 : 1)
			.buttonStyle(.borderless)
			.tint(.accentColor)
			.padding(.bottom, 8)
			.font(.subheadline)
			.overlay {
				if let error {
					Text(error)
						.fixedSize(horizontal: false, vertical: true)
						.font(.caption)
						.padding()
						.background(.thickMaterial)
				} else if isLoading {
					ProgressView()
						.padding(.bottom, 8)
				}
			}

			HStack {
				if let filename = attachment.filename {
					Text(filename)
				}

				Spacer()

				if let formattedContentLength = formattedContentLength(attachment.contentLength) {
					Text(formattedContentLength)
				}
			}
			.font(.caption)
			.foregroundColor(.secondary)
			.padding(.bottom, 8)

			Text(attachment.url)
				.foregroundColor(.secondary)
				.font(.caption2)
				.textSelection(.enabled)
				.frame(maxWidth: .infinity)
		}
		.frame(maxWidth: 200, maxHeight: 200)
		.padding()
		.background(.ultraThinMaterial)
		.cornerRadius(8)
	}

	func formattedContentLength(_ contentLength: Int?) -> String? {
		guard let contentLength, contentLength > 0 else {
			return nil
		}

		let numberFormatter = ByteCountFormatter()
		return numberFormatter.string(for: contentLength)
	}

	func load() {
		isLoading = true

		do {
			let remoteAttachment = try RemoteAttachment(
				url: attachment.url,
				contentDigest: attachment.contentDigest,
				secret: attachment.secret,
				salt: attachment.salt,
				nonce: attachment.nonce,
				scheme: .https
			)

			Task {
				do {
					let encodedContent = try await remoteAttachment.content()
					switch encodedContent.type {
					case ContentTypeAttachment:
						let attachment: Attachment = try encodedContent.decoded()
						var messageAttachment = DB.MessageAttachment(messageID: message.id ?? -1, mimeType: attachment.mimeType, filename: attachment.filename)

						try messageAttachment.save(data: attachment.data)
						try messageAttachment.save()

						let savedMessageAttachment = messageAttachment
						await MainActor.run {
							var message = message
							withAnimation {
								message.attachments.append(savedMessageAttachment)
								presenter.message = message
							}
						}
						print("SAVED MESSAGE ATTACHMENT")

					default:
						await MainActor.run {
							self.isLoading = false
							self.error = "Unknown remote content type: \(encodedContent.type)"
						}
					}
				} catch {
					await MainActor.run {
						self.isLoading = false
						self.error = error.localizedDescription
					}
				}
			}
		} catch {
			print("ERROR LOADING ATTACHMENT \(error)")
			isLoading = false
			self.error = error.localizedDescription
		}
	}
}

#if DEBUG
struct RemoteAttachmentMessageView_Previews: PreviewProvider {
	static var previews: some View {
		RemoteAttachmentMessageView(presenter: MessagePresenter(message: DB.Message.previewImage), message: DB.Message.previewImage, attachment: DB.RemoteAttachment.previewImage)
	}
}
#endif
