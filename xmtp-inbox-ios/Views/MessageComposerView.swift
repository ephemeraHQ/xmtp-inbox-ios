//
//  MessageComposerView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import Combine
import Introspect
import SwiftUI
import XMTP

class ComposerTextFieldDelegate: NSObject, UITextViewDelegate {
	var onTyping: (() async -> Void)?

	func textViewDidChange(_: UITextView) {
		Task {
			await onTyping?()
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
	@State private var isSending = false
	@Binding var offset: CGFloat
	@StateObject private var keyboardObserver = KeyboardObserver()

	@FocusState var isFocused

	// Attachment properties
	@State private var attachment: XMTP.Attachment?
	@State var publisher = PassthroughSubject<String, Never>()

	var onSend: (String, XMTP.Attachment?) async -> Void
	var onTyping: () async -> Void

	var body: some View {
		VStack(alignment: .leading) {
			if let attachment {
				VStack(alignment: .leading) {
					ZStack {
						AttachmentPreviewView(attachment: attachment)
							.padding(.top, 8)
							.overlay {
								VStack {
									HStack {
										Spacer()
										Button(action: {
											withAnimation {
												self.attachment = nil
											}
										}) {
											Image(systemName: "xmark.circle.fill")
												.resizable()
												.frame(width: 24, height: 24)
												.foregroundColor(.backgroundTertiary)
												.padding(8)
												.contrast(10)
										}
										.padding(.top, 8)
									}
									Spacer()
								}
							}
					}
					Divider()
				}
				.transition(.scale(scale: 0, anchor: .bottomLeading).combined(with: .opacity))
				.animation(.easeInOut, value: attachment)
			}

			HStack(spacing: 0) {
				MessageAttachmentComposerButton(attachment: $attachment)
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
					.onChange(of: text) { _ in
						publisher.send("")
					}
					.onReceive(
						publisher.throttle(
							for: .seconds(1),
							scheduler: DispatchQueue.main,
							latest: true
						)
					) { _ in
						if text.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
							Task {
								await onTyping()
							}
						}
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
					.opacity(isSending ? 0 : 1)
					.disabled(isSending)
				}
				.overlay {
					if isSending {
						ZStack {
							Color.backgroundTertiary
								.frame(width: 32, height: 32)
								.roundCorners(16, corners: [.topLeft, .topRight, .bottomLeft])

							ProgressView()
						}
					}
				}
			}
		}
		.padding(.horizontal, 8)
		.overlay(RoundedCorner(radius: 16, corners: [.topLeft, .topRight, .bottomLeft]).stroke(Color.actionPrimary, lineWidth: 2))
	}

	func send() {
		if text.trimmingCharacters(in: .whitespacesAndNewlines) == "" && attachment == nil {
			return
		}

		withAnimation {
			self.isSending = true
		}

		Task.detached(priority: .userInitiated) {
			await onSend(text, attachment)
			await MainActor.run {
				self.text = ""
				self.attachment = nil
				self.isSending = false
			}
		}
	}
}

struct MessageComposerView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			MessageComposerView(offset: .constant(0), onSend: { _, _ in
				try? await Task.sleep(for: .seconds(2))
			}, onTyping: {
				print("Typing")
			})
			.padding(.horizontal)
		}
	}
}
