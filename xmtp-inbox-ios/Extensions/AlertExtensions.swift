//
//  AlertExtensions.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/25/23.
//

import AlertToast
import Foundation

extension AlertToast {
	static func error(_ errorMessage: String?) -> AlertToast {
		return AlertToast(
			type: .regular,
			title: errorMessage,
			style: .style(
				backgroundColor: .actionNegative,
				titleColor: .actionPrimaryText
			)
		)
	}
}
