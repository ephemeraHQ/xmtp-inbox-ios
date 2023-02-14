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
				.frame(maxHeight: 100)
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

struct MessageComposerView: View {
	var accessoryView: UIView?

	@State private var text: String = ""
	@State private var originalOffset = CGFloat()
	@State private var photosPickerItem: PhotosPickerItem?
	@State private var attachment: XMTP.Attachment?

	@Binding var offset: CGFloat
	@StateObject private var keyboardObserver = KeyboardObserver()

	@FocusState var isFocused

	var onSend: (String, XMTP.Attachment?) async -> Void

	func loadTransferable(from imageSelection: PhotosPickerItem) {
		Task {
			do {
				guard let imageData = try await imageSelection.loadTransferable(type: Data.self) else {
					await MainActor.run {
						self.photosPickerItem = nil
					}
					print("no images data")
					return
				}

				await MainActor.run {
					self.attachment = XMTP.Attachment(filename: imageSelection.itemIdentifier ?? "attachment", mimeType: "image/png", data: imageData)
					self.photosPickerItem = nil
				}
			} catch {
				print("Error loading transferrable: \(error)")
			}
		}
	}

	var body: some View {
		VStack(alignment: .leading) {
			if let attachment {
				AttachmentPreviewView(attachment: attachment)
			}

			HStack(alignment: .top, spacing: 0) {
				PhotosPicker(selection: $photosPickerItem, matching: .images) {
					Image(systemName: "photo")
						.symbolRenderingMode(.multicolor)
						.resizable()
						.scaledToFit()
						.tint(.accentColor)
				}
				.frame(width: 24, height: 24)
				.padding(.top, 12)
				.padding(.leading, 12)
				.onChange(of: photosPickerItem) { item in
					if let item {
						loadTransferable(from: item)
					}
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
				.padding(.top, 6)
			}
		}
		.padding(.horizontal, 8)
		.overlay(RoundedCorner(radius: 16, corners: [.topLeft, .topRight, .bottomLeft]).stroke(Color.actionPrimary, lineWidth: 2))
	}

	func send() {
		if text.trimmingCharacters(in: .whitespacesAndNewlines) == "" && attachment == nil {
			return
		}

		Task {
			await onSend(text, attachment)
			await MainActor.run {
				self.text = ""
			}
		}
	}
}

struct MessageComposerView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			MessageComposerView(offset: .constant(0)) { _, _ in }
		}
	}
}
