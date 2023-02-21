//
//  MessageTextView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/18/23.
//

import SwiftUI
import UIKit

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
		uiView.textColor = textColor
		uiView.backgroundColor = .clear
		uiView.linkTextAttributes = [.foregroundColor: textColor]
	}
}
