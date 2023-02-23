//
//  TextFieldWithLoader.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/23/23.
//

import SwiftUI

struct TextFieldWithLoader: View {
	var title: String?
	var titleKey: LocalizedStringKey?
	@Binding var text: String
	var isLoading = false

	init(_ titleKey: LocalizedStringKey, text: Binding<String>, isLoading: Bool) {
		self.titleKey = titleKey
		_text = text
		self.isLoading = isLoading
	}

	var body: some View {
		ZStack {
			if let title = title {
				TextField(title, text: $text.animation())
			} else if let titleKey = titleKey {
				TextField(titleKey, text: $text.animation())
			}
			if isLoading {
				HStack {
					Spacer()
					ProgressView()
				}
				.transition(.opacity)
			}
		}
	}
}

struct TextFieldWithLoader_Previews: PreviewProvider {
	static var previews: some View {
		List {
			TextFieldWithLoader("Not Loading", text: .constant(""), isLoading: false)
			TextFieldWithLoader("Loading", text: .constant(""), isLoading: true)
		}
	}
}
