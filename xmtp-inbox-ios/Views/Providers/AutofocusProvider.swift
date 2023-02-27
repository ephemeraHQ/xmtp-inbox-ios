//
//  AutofocusProvider.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/27/23.
//

import SwiftUI

struct AutofocusProvider<Content: View>: View {
	@FocusState var isFocused
	var content: () -> Content

	var body: some View {
		content()
			.focused($isFocused)
			.onAppear {
				self.isFocused = true
			}
	}
}

struct AutofocusProvider_Previews: PreviewProvider {
	static var previews: some View {
		AutofocusProvider {
			TextField("Focus me", text: .constant("hi"))
		}
	}
}
