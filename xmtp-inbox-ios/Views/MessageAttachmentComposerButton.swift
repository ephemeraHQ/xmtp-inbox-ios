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
	@Environment(\.dismiss) var dismiss
	@State private var item: PhotosPickerItem?
	@Binding var attachment: XMTP.Attachment?
	@State private var web3StorageToken: String?

	init(attachment: Binding<XMTP.Attachment?>) {
		_attachment = attachment

		if let token = AppGroup.keychain[Web3Storage.keychainKey] {
			_web3StorageToken = State(wrappedValue: token)
		}
	}

	var body: some View {
		if web3StorageToken != nil {
			PhotosPicker(selection: $item) {
				icon
			}
			.onChange(of: item) { newItem in
				if let newItem {
					loadTransferable(from: newItem)
				}
			}
		} else {
			SheetButton(label: {
				icon
			}, sheet: { dismiss in
				Web3StorageTokenView { token in
					AppGroup.keychain[Web3Storage.keychainKey] = token
					self.web3StorageToken = token
					dismiss()
				}
			})
		}
	}

	var icon: some View {
		Image(systemName: "photo")
			.resizable()
			.scaledToFit()
			.tint(.accentColor)
			.symbolRenderingMode(.multicolor)
			.frame(width: 24, height: 24)
			.padding(.leading, 8)
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
