//
//  MessageListEntryView.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/17/23.
//

import SwiftUI

struct MessageListEntryView: View {
	var messagelistEntry: MessageListEntry

	var body: some View {
		switch messagelistEntry {
		case let .message(message):
			MessageCellView(message: message)
		case let .timestamp(date):
			HStack {
				Spacer()
				Text("\(date, formatter: dateFormatter)")
					.font(.caption)
					.foregroundColor(.secondary)
				Spacer()
			}
		}
	}

	var dateFormatter: DateFormatter {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMM d, h:mm a"
		return formatter
	}
}

#if DEBUG
struct MessageListEntryView_Previews: PreviewProvider {
	static var previews: some View {
		MessageListEntryView(messagelistEntry: .message(DB.Message.preview))
	}
}
#endif
