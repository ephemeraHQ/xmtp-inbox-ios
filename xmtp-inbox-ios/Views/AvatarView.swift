//
//  EnsImageView.swift
//  xmtp-inbox-ios
//
//  Created by Elise Alix on 1/16/23.
//

import IGIdenticon
import SwiftUI
import web3

struct AvatarView: View {
	var imageSize: CGFloat

	var peerAddress: String

	@State private var ensImage: UIImage?

	var body: some View {
		AvatarProvider(address: peerAddress, size: imageSize) { image in
			if let image {
				image
					.resizable()
					.scaledToFill()
					.clipShape(Circle())
					.frame(width: imageSize, height: imageSize)
			} else {
				Color.backgroundSecondary
					.clipShape(Circle())
					.frame(width: imageSize, height: imageSize)
			}
		}
	}
}
