//
//  MessageComposerView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import Introspect
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

struct MessageComposerView: View {
	var accessoryView: UIView?

	@State private var text: String = ""
	@State private var isSending = false

	@State private var originalOffset = CGFloat()
	@Binding var offset: CGFloat
	@StateObject private var keyboardObserver = KeyboardObserver()

	@FocusState var isFocused

	var onSend: (String) async -> Void

	var body: some View {
		HStack {
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
		.disabled(isSending)
	}

	func send() {
		if text.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
			return
		}

		isSending = true
		Task {
			await onSend(text)
			await MainActor.run {
				self.text = ""
				self.isSending = false
//				self.isFocused = true
			}
		}
	}
}

struct MessageComposerView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			MessageComposerView(offset: .constant(0)) { _ in }
		}
	}
}
