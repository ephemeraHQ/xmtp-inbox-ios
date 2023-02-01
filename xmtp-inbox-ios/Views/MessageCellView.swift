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

	var message: DecodedMessage

	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				if isFromMe {
					Spacer()
				}
				Text(bodyText)
					.foregroundColor(textColor)
					.padding()
					.background(background)
				if !isFromMe {
					Spacer()
				}
			}
		}
	}

	var bodyText: String {
		do {
			return try message.content() ?? ""
		} catch {
			print("Error getting message body: \(error)")
			return ""
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
			MessageCellView(isFromMe: true, message: DecodedMessage.preview(body: "Hi, how is it going?", senderAddress: "0x00", sent: Date()))
		}
		.listStyle(.plain)
	}
}
