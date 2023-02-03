//
//  MessageCellView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/7/22.
//

import SwiftUI
import XMTP

struct MessageCellView: View {
	var isFromMe: Bool

	var message: DB.Message

	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				if isFromMe {
					Spacer()
				}
				Text(message.body)
					.foregroundColor(textColor)
					.padding()
					.background(background)
				if !isFromMe {
					Spacer()
				}
			}
		}
	}

	var background: some View {
		if isFromMe {
			return Color.actionPrimary.roundCorners(16, corners: [.topLeft, .topRight, .bottomLeft])
		} else {
			return Color.backgroundSecondary.roundCorners(16, corners: [.topRight, .bottomLeft, .bottomRight])
		}
	}

	var textColor: Color {
		if isFromMe {
			return .actionPrimaryText
		} else {
			return .textPrimary
		}
	}
}

struct MessageCellView_Previews: PreviewProvider {
	static var previews: some View {
		List {
			MessageCellView(isFromMe: true, message: DB.Message.preview)
		}
		.listStyle(.plain)
	}
}
