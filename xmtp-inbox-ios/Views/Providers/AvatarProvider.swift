//
//  AvatarProvider.swift
//  xmtp-inbox-ios
//
//  Created by Pat on 2/17/23.
//

import SwiftUI

struct AvatarProvider<Content: View>: View {
	@State private var avatar: Image?

	var address: String
	var size: CGFloat
	@ViewBuilder var content: (Image?) -> Content

	@ViewBuilder
	var body: some View {
		content(avatar)
			.onAppear {
				if let image = Avatars.shared.cachedAvatarFor(address: address, size: size) {
					self.avatar = Image(uiImage: image)
				}
			}
			.task {
				if let image = await Avatars.shared.loadAvatarFor(address: address, size: size) {
					await MainActor.run {
						withAnimation {
							self.avatar = Image(uiImage: image)
						}
					}
				}
			}
	}
}
