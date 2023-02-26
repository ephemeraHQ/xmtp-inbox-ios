//
//  MessageAttachmentComposerButton.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/24/23.
//

import PhotosUI
import SwiftUI
import XMTP

struct MessageAttachmentComposerButton: View {
	@State private var item: PhotosPickerItem?
	@Binding var attachment: XMTP.Attachment?

	var body: some View {
		PhotosPicker(selection: $item) {
			Image(systemName: "photo")
				.resizable()
				.scaledToFit()
				.tint(.accentColor)
				.symbolRenderingMode(.multicolor)
				.frame(width: 24, height: 24)
				.padding(.leading, 8)
		}
		.onChange(of: item) { newItem in
			if let newItem {
				loadTransferable(from: newItem)
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
					withAnimation {
						self.attachment = XMTP.Attachment(filename: filename, mimeType: mimeType, data: imageData)
						self.item = nil
					}
				}
			} catch {
				print("Error loading transferrable: \(error)")
			}
		}
	}
}

struct MessageAttachmentComposerButton_Previews: PreviewProvider {
	static var previews: some View {
		MessageAttachmentComposerButton(attachment: .constant(nil))
	}
}
