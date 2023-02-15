//
//  WalletSelectionSheet.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/14/23.
//

import SwiftUI

struct WalletSelectionSheet: View {
	var onChoose: (WalletProvider) -> Void

	var body: some View {
		NavigationStack {
			List {
				Button(action: {
					onChoose(.rainbow)
				}) {
					Text("Rainbow")
				}
				Button(action: {
					onChoose(.metamask)
				}) {
					Text("MetaMask")
				}
				Button(action: {
					onChoose(.walletconnect)
				}) {
					Text("WalletConnect")
				}
			}
			.navigationTitle("Connect a Wallet")
		}
	}
}

struct WalletSelectionSheet_Previews: PreviewProvider {
	static var previews: some View {
		WalletSelectionSheet { _ in }
	}
}
