//
//  MessageComposerView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import Introspect
import PhotosUI
import SwiftUI
import XMTP

struct AttachmentPreviewView: View {
	var attachment: XMTP.Attachment
	@State private var image: Image?

	init(attachment: XMTP.Attachment) {
		self.attachment = attachment
	}

	var body: some View {
		if let image {
			image
				.resizable()
				.scaledToFit()
				.aspectRatio(contentMode: .fit)
				.frame(height: 200)
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

class KeyboardObserver: ObservableObject {
	@Published var isVisible = false

	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasHidden(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
	}

	@objc private func keyboardWasShown(notification _: NSNotification) {
		isVisible = true
	}

	@objc private func keyboardWasHidden(notification _: NSNotification) {
		isVisible = false
	}
}

struct MessageComposerView: View {
	var accessoryView: UIView?

	@State private var text: String = ""
	@State private var originalOffset = CGFloat()
	@Binding var offset: CGFloat
	@StateObject private var keyboardObserver = KeyboardObserver()

	@FocusState var isFocused
	@State private var item: PhotosPickerItem?
	@State private var attachment: XMTP.Attachment?

	var onSend: (String, Attachment?) async -> Void

	var body: some View {
		VStack {
			if let attachment {
				AttachmentPreviewView(attachment: attachment)
			}
			HStack(spacing: 0) {
				PhotosPicker(selection: $item) {
					Image(systemName: "photo")
						.resizable()
						.scaledToFit()
						.frame(height: 24)
						.foregroundColor(Color.accentColor)
						.padding(.leading, 4)
				}

				TextField("Type a message…", text: $text, axis: .vertical)
					.introspectTextView { textField in
						textField.inputAccessoryView = UIHostingController(rootView: GeometryReader { geo in
							Color.clear
								.onChange(of: geo.frame(in: .global)) { frame in
									self.offset = max(0, frame.minY - originalOffset)
								}
								.onReceive(keyboardObserver.$isVisible) { isVisible in
									withAnimation {
										if isVisible {
											self.originalOffset = geo.frame(in: .global).minY
											self.offset = 0
										} else {
											self.originalOffset = geo.frame(in: .global).minY
											self.offset = 0
										}
									}
								}
						}).view
					}
					.lineLimit(4)
					.padding(12)
					.onSubmit {
						send()
					}

				ZStack {
					Color.actionPrimary
						.frame(width: 32, height: 32)
						.roundCorners(16, corners: [.topLeft, .topRight, .bottomLeft])
					Button(action: send) {
						Label("Send", systemImage: "arrow.up")
							.font(.system(size: 16))
							.labelStyle(.iconOnly)
							.foregroundColor(Color.actionPrimaryText)
					}
				}
			}
			.padding(.horizontal, 8)
			.overlay(RoundedCorner(radius: 16, corners: [.topLeft, .topRight, .bottomLeft]).stroke(Color.actionPrimary, lineWidth: 2))
			.onChange(of: item) { item in
				if let item {
					loadTransferable(from: item)
				}
			}
		}
	}

	func send() {
		if text.trimmingCharacters(in: .whitespacesAndNewlines) == "" && attachment == nil {
			return
		}

		Task {
			await onSend(text, attachment)
			await MainActor.run {
				self.text = ""
				self.attachment = nil
			}
		}
	}

	func loadTransferable(from imageSelection: PhotosPickerItem) {
		Task {
			do {
				guard let imageData = try await imageSelection.loadTransferable(type: Data.self) else {
					await MainActor.run {
						self.item = nil
					}
					print("no images data")
					return
				}

				guard let contentType = imageSelection.supportedContentTypes.first,
				      let mimeType = contentType.preferredMIMEType
				else {
					return
				}

				let ext = mimeType.split(separator: "/")[1]
				let filename = "\(imageSelection.itemIdentifier ?? "attachment").\(ext)"

				await MainActor.run {
					self.attachment = XMTP.Attachment(filename: filename, mimeType: mimeType, data: imageData)
					self.item = nil
				}
			} catch {
				print("Error loading transferrable: \(error)")
			}
		}
	}
}

struct MessageComposerView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			PreviewClientProvider { _ in
				MessageComposerView(offset: .constant(0)) { _, _ in }
			}
		}
	}
}
